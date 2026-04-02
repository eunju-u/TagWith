import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_strings.dart';
import '../data/models.dart';
import '../services/transaction_service.dart';

/// 앱의 모든 거래 데이터를 관리하고 UI에 상태 변화를 알리는 핵심 프로바이더입니다.
class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  
  // 로딩 상태 관리
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 태그 및 통계 데이터
  List<Relation> _customRelations = [];
  List<Relation> get customRelations => _customRelations;
  
  Statistics? _statistics;
  Statistics? get statistics => _statistics;
  
  // 고정 지출 및 결제 수단 데이터
  List<RecurringTransaction> _recurringTransactions = [];
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  
  List<PaymentMethodModel> _paymentMethods = [];
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  
  // 데이터 로컬 저장을 위한 보안 저장소 (보안이 필요한 설정값용)
  final _storage = const FlutterSecureStorage();
  static const String _budgetKey = 'monthly_budget';
  static const String _calFilterTypeKey = 'cal_filter_type';
  static const String _calFilterCatsKey = 'cal_filter_cats';
  static const String _calFilterRelsKey = 'cal_filter_rels';
  static const String _calFilterMethodsKey = 'cal_filter_methods';

  // 한 달 예산 설정 (기본값: 1,000,000원)
  double _monthlyBudget = 1000000.0; 
  double get monthlyBudget => _monthlyBudget;

  TransactionProvider() {
    _loadBudget();    // 저장된 예산 불러오기
    _loadFilters();   // 저장된 필터 설정 불러오기
  }

  /// 저장된 예산 값을 불러옵니다.
  Future<void> _loadBudget() async {
    final savedBudget = await _storage.read(key: _budgetKey);
    if (savedBudget != null) {
      _monthlyBudget = double.tryParse(savedBudget) ?? 1000000.0;
      notifyListeners();
    }
  }

  /// 새로운 예산을 설정하고 로컬에 저장합니다.
  Future<void> updateMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    await _storage.write(key: _budgetKey, value: budget.toString());
    notifyListeners();
  }

  /// 이전에 달력에서 설정했던 필터들을 복원합니다.
  Future<void> _loadFilters() async {
    final type = await _storage.read(key: _calFilterTypeKey);
    if (type != null) {
      _calendarSelectedType = type == 'income' ? TransactionType.income : TransactionType.expense;
    }
    final cats = await _storage.read(key: _calFilterCatsKey);
    if (cats != null) {
      try {
        _calendarSelectedCategories.clear();
        _calendarSelectedCategories.addAll(List<String>.from(json.decode(cats)));
      } catch (_) {}
    }
    final rels = await _storage.read(key: _calFilterRelsKey);
    if (rels != null) {
      try {
        _calendarSelectedRelations.clear();
        _calendarSelectedRelations.addAll(List<String>.from(json.decode(rels)));
      } catch (_) {}
    }
    final methods = await _storage.read(key: _calFilterMethodsKey);
    if (methods != null) {
      try {
        _calendarSelectedPaymentMethods.clear();
        _calendarSelectedPaymentMethods.addAll(List<String>.from(json.decode(methods)));
      } catch (_) {}
    }
    notifyListeners();
  }

  /// 서버로부터 모든 거래, 카테고리, 태그, 통계 데이터를 불러옵니다.
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 여러 API를 병렬로 호출하여 성능 최적화
      final results = await Future.wait([
        _service.getTransactions(),
        _service.getCategories(),
        _service.getUserCategories(),
        _service.getTags(),
        _service.getStatistics(year: DateTime.now().year, month: DateTime.now().month),
        _service.getRecurringTransactions(),
        _service.getPaymentMethods(),
      ]);

      _transactions = results[0] as List<Transaction>;
      final globalCats = results[1] as List<Category>;
      final userCats = results[2] as List<Category>;
      _allCategories = [...globalCats, ...userCats];
      
      // 내역의 카테고리 객체를 실제 카테고리 리스트와 동기화 (색상 및 이름 일관성 유지)
      _transactions = _transactions.map((t) {
        final realCat = _allCategories.firstWhere(
          (c) => c.name == t.category.name,
          orElse: () => t.category,
        );
        return t.copyWith(category: realCat);
      }).toList();
      
      _customRelations = results[3] as List<Relation>;
      _statistics = results[4] as Statistics?;
      _recurringTransactions = results[5] as List<RecurringTransaction>;
      _paymentMethods = results[6] as List<PaymentMethodModel>;
      
      debugPrint('거래 데이터 로드 완료: ${_transactions.length}건, 카테고리: ${_allCategories.length}개');
    } catch (e) {
      debugPrint('거래 데이터 로드 중 오류 발생: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// 특정 년/월의 통계 데이터를 상세히 가져옵니다.
  Future<void> loadStatistics({int? year, int? month}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _statistics = await _service.getStatistics(year: year, month: month);
    } catch (e) {
      debugPrint('통계 로드 중 오류 발생: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Transaction> _transactions = [];
  List<Category> _allCategories = [];
  List<Category> get allCategories => _allCategories;

  /// 현재 달력 필터 조건(타입, 카테고리, 태그, 결제수단)이 적용된 거래 내역을 반환합니다.
  List<Transaction> get calendarFilteredTransactions {
     return _transactions.where((t) {
      final matchesType = _calendarSelectedType == null || t.type == _calendarSelectedType;
      
      // ID 또는 이름으로 매칭 (맵핑 전후 모두 대응 가능하도록)
      final matchesCategory = _calendarSelectedCategories.isEmpty || 
          _calendarSelectedCategories.contains(t.category.id) || 
          _calendarSelectedCategories.any((idOrName) => t.category.name == idOrName);

      final matchesRelation = _calendarSelectedRelations.isEmpty || t.relations.any((r) => _calendarSelectedRelations.contains(r.id) || _calendarSelectedRelations.contains(r.name));
      final matchesPaymentMethod = _calendarSelectedPaymentMethods.isEmpty || _calendarSelectedPaymentMethods.contains(t.paymentMethod);
      
      return matchesType && matchesCategory && matchesRelation && matchesPaymentMethod;
    }).toList();
  }

  /// 특정 날짜가 인자로 받은 날짜와 같은 날인지 확인합니다 (타임존/시간 성분 무시).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 달력 화면에서 선택된 필터들
  TransactionType? _calendarSelectedType;
  final List<String> _calendarSelectedCategories = [];
  final List<String> _calendarSelectedRelations = [];
  final List<String> _calendarSelectedPaymentMethods = [];

  TransactionType? get calendarSelectedType => _calendarSelectedType;
  List<String> get calendarSelectedCategories => _calendarSelectedCategories;
  List<String> get calendarSelectedRelations => _calendarSelectedRelations;
  List<String> get calendarSelectedPaymentMethods => _calendarSelectedPaymentMethods;

  /// 달력에서 하나 이상의 필터가 적용되어 있는지 확인합니다.
  bool get hasCalendarFilters =>
      _calendarSelectedType != null ||
      _calendarSelectedCategories.isNotEmpty ||
      _calendarSelectedRelations.isNotEmpty ||
      _calendarSelectedPaymentMethods.isNotEmpty;

  /// 새로운 거래 내역을 추가합니다.
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final savedTransaction = await _service.createTransaction(transaction);
      if (savedTransaction != null) {
        // 서버에서 받은 데이터를 카테고리 객체와 연결하여 리스트에 추가
        final hydrated = savedTransaction.copyWith(
          category: _allCategories.firstWhere((c) => c.name == savedTransaction.category.name, orElse: () => savedTransaction.category),
        );
        _transactions.add(hydrated);
        notifyListeners();
        return true;
      }
      debugPrint('addTransaction failed: Server returned null');
      return false;
    } catch (e) {
      debugPrint('addTransaction error: $e');
      return false;
    }
  }

  /// 기존 거래 내역을 삭제합니다.
  Future<bool> deleteTransaction(String id) async {
    final success = await _service.deleteTransaction(id);
    if (success) {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    }
    return success;
  }

  /// 거래 내역을 수정합니다.
  Future<bool> updateTransaction(Transaction transaction) async {
    final updated = await _service.updateTransaction(transaction);
    if (updated != null) {
      final hydrated = updated.copyWith(
        category: _allCategories.firstWhere((c) => c.name == updated.category.name, orElse: () => updated.category),
      );
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = hydrated;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 결제 수단별 총 지출액을 계산하여 맵 형태로 반환합니다.
  Map<String, double> getPaymentMethodSpending({bool forStats = true, int? year, int? month}) {
    final map = <String, double>{};
    var transactions = _transactions; 
    
    // 기간 필터링
    if (year != null || month != null) {
      transactions = transactions.where((t) {
        bool matches = true;
        if (year != null) matches = matches && t.date.year == year;
        if (month != null) matches = matches && t.date.month == month;
        return matches;
      }).toList();
    }
    
    // 사용 중인 모든 결제수단을 0원으로 초기화
    for (var method in _paymentMethods) {
      map[method.name] = 0;
    }

    // 실제 지출 내역 합산
    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + t.amount;
    }
    return map;
  }

  /// 특정 결제 수단들의 총합을 구합니다. (필터 적용 여부 선택 가능, 기본값: 필터 미적용)
  double getTotalByMethod(TransactionType type, List<String> methodNames, {int? year, DateTime? month, bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) {
      final matchesType = t.type == type;
      final matchesMethod = methodNames.contains(t.paymentMethod);
      bool matchesPeriod = true;
      if (year != null) {
        matchesPeriod = t.date.year == year;
      } else if (month != null) {
        matchesPeriod = t.date.year == month.year && t.date.month == month.month;
      }
      return matchesType && matchesMethod && matchesPeriod;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 결제 수단들에 포함되지 않는 내역들의 총합을 구합니다. (필터 적용 여부 선택 가능, 기본값: 필터 미적용)
  double getTotalByOtherMethods(TransactionType type, List<String> excludedMethodNames, {int? year, DateTime? month, bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) {
      final matchesType = t.type == type;
      final isExcluded = excludedMethodNames.contains(t.paymentMethod);
      bool matchesPeriod = true;
      if (year != null) {
        matchesPeriod = t.date.year == year;
      } else if (month != null) {
        matchesPeriod = t.date.year == month.year && t.date.month == month.month;
      }
      return matchesType && !isExcluded && matchesPeriod;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 카테고리별 지출/수입 분석 맵을 반환합니다.
  Map<String, double> getCategorySpending(TransactionType type, {bool forStats = false, int? year, int? month}) {
    final map = <String, double>{};
    final transactions = _transactions.where((t) {
      final matchesType = t.type == type;
      bool matchesPeriod = true;
      if (year != null && month != null) {
        matchesPeriod = t.date.year == year && t.date.month == month;
      } else if (year != null) {
        matchesPeriod = t.date.year == year;
      }
      return matchesType && matchesPeriod;
    });

    for (var t in transactions) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    return map;
  }

  /// 태그(Relation)별 지출 분석 맵을 반환합니다.
  Map<String, double> getTagSpending({bool forStats = false, int? year, int? month}) {
    final map = <String, double>{};
    final transactions = _transactions.where((t) {
      final matchesType = t.type == TransactionType.expense;
      bool matchesPeriod = true;
      if (year != null && month != null) {
        matchesPeriod = t.date.year == year && t.date.month == month;
      } else if (year != null) {
        matchesPeriod = t.date.year == year;
      }
      return matchesType && matchesPeriod;
    });

    for (var t in transactions) {
      for (var rel in t.relations) {
        map[rel.name] = (map[rel.name] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// 차트용 월별 수입 및 지출 추이 데이터를 생성합니다.
  Map<DateTime, Map<String, double>> getMonthlyTrend({required DateTime rootDate, int months = 6}) {
    final Map<DateTime, Map<String, double>> trend = {};
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(rootDate.year, rootDate.month - i, 1);
      final monthTransactions = _transactions.where((t) => t.date.year == date.year && t.date.month == date.month);
      
      final income = monthTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      final expense = monthTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
      
      trend[date] = {'income': income, 'expense': expense};
    }
    return trend;
  }

  /// 특정 월의 총 수입액을 반환합니다. (기본값: 필터 미적용)
  double getTotalIncomeByMonth(DateTime month, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.income &&
        t.date.year == month.year &&
        t.date.month == month.month
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 월의 총 지출액을 반환합니다. (기본값: 필터 미적용)
  double getTotalExpenseByMonth(DateTime month, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == month.year &&
        t.date.month == month.month
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 연도의 총 수입액을 반환합니다. (기본값: 필터 미적용)
  double getTotalIncomeByYear(int year, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.income &&
        t.date.year == year
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 연도의 총 지출액을 반환합니다. (기본값: 필터 미적용)
  double getTotalExpenseByYear(int year, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == year
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 날짜의 총 수입액을 반환합니다. (기본값: 필터 미적용)
  double getTotalIncomeByDate(DateTime date, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.income &&
        _isSameDay(t.date, date)
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 날짜의 총 지출액을 반환합니다. (기본값: 필터 미적용)
  double getTotalExpenseByDate(DateTime date, {bool useFilters = false}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) =>
        t.type == TransactionType.expense &&
        _isSameDay(t.date, date)
    ).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// 특정 날짜의 거래 내역 리스트를 반환합니다. (기본값: 필터 적용)
  List<Transaction> getTransactionsByDate(DateTime date, {bool useFilters = true}) {
    final list = useFilters ? calendarFilteredTransactions : _transactions;
    return list.where((t) => _isSameDay(t.date, date)).toList();
  }

  /// 새로운 결제 수단을 추가합니다.
  Future<bool> addPaymentMethod(PaymentMethodModel method) async {
    final result = await _service.createPaymentMethod(method);
    if (result != null) {
      _paymentMethods.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 결제 수단 정보를 수정합니다.
  Future<bool> updatePaymentMethod(PaymentMethodModel method) async {
    final result = await _service.updatePaymentMethod(method);
    if (result != null) {
      final index = _paymentMethods.indexWhere((m) => m.id == method.id);
      if (index != -1) {
        _paymentMethods[index] = result;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 결제 수단을 삭제합니다.
  Future<bool> deletePaymentMethod(String id) async {
    final success = await _service.deletePaymentMethod(id);
    if (success) {
      _paymentMethods.removeWhere((m) => m.id == id);
      // [최적화] 결제 수단 삭제 시 해당 수단을 쓰던 내역들의 스냅샷(유형|이름) 정보를 갱신하기 위해 내역 재로그
      await loadTransactions(); 
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 새로운 고정 지출 설정을 추가합니다.
  Future<bool> addRecurringTransaction(RecurringTransaction recurring) async {
    final result = await _service.createRecurringTransaction(recurring);
    if (result != null) {
      _recurringTransactions.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 기존 고정 지출 설정을 수정합니다 (활성화 상태 등).
  Future<bool> updateRecurringTransaction(String id, Map<String, dynamic> data) async {
    final result = await _service.updateRecurringTransaction(id, data);
    if (result != null) {
      final index = _recurringTransactions.indexWhere((r) => r.id == id);
      if (index != -1) {
        _recurringTransactions[index] = result;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 새로운 사용자 정의 카테고리를 추가합니다.
  Future<void> addCustomCategory(Category category) async {
    final result = await _service.createUserCategory(category);
    if (result != null) {
      _allCategories.add(result);
      notifyListeners();
    }
  }

  /// 사용자 정의 카테고리를 수정합니다.
  Future<bool> updateCustomCategory(Category category) async {
    final result = await _service.updateUserCategory(category);
    if (result != null) {
      final index = _allCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _allCategories[index] = result;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 사용자 정의 카테고리를 삭제합니다.
  Future<bool> deleteCustomCategory(String id) async {
    final success = await _service.deleteUserCategory(id);
    if (success) {
      _allCategories.removeWhere((c) => c.id == id);
      notifyListeners();
    }
    return success;
  }

  /// 새로운 커스텀 태그(Relation)를 추가합니다.
  Future<void> addCustomRelation(String name) async {
    final rel = await _service.createTag(name);
    if (rel != null) {
      _customRelations.add(rel);
      notifyListeners();
    }
  }

  /// 고정 지출 설정을 삭제합니다.
  Future<bool> deleteRecurringTransaction(String id) async {
    final success = await _service.deleteRecurringTransaction(id);
    if (success) {
      _recurringTransactions.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- 필터링 관련 ---

  /// 거래 타입(수입/지출) 필터를 설정합니다.
  void setTypeFilter(TransactionType? type, {bool forStats = false}) {
    if (forStats) {
      _statsSelectedType = type;
    } else {
      _calendarSelectedType = type;
      _storage.write(key: _calFilterTypeKey, value: type?.name);
    }
    notifyListeners();
  }

  /// 특정 카테고리 필터를 켜거나 끕니다.
  void toggleCategoryFilter(String categoryId, {bool forStats = false}) {
    final list = forStats ? _statsSelectedCategories : _calendarSelectedCategories;
    if (list.contains(categoryId)) {
      list.remove(categoryId);
    } else {
      list.add(categoryId);
    }
    if (!forStats) {
      _storage.write(key: _calFilterCatsKey, value: json.encode(list));
    }
    notifyListeners();
  }

  /// 특정 태그(Relation) 필터를 켜거나 끕니다.
  void toggleRelationFilter(String relationId, {bool forStats = false}) {
    final list = forStats ? _statsSelectedRelations : _calendarSelectedRelations;
    if (list.contains(relationId)) {
      list.remove(relationId);
    } else {
      list.add(relationId);
    }
    if (!forStats) {
      _storage.write(key: _calFilterRelsKey, value: json.encode(list));
    }
    notifyListeners();
  }

  /// 특정 결제 수단 필터를 켜거나 끕니다.
  void togglePaymentMethodFilter(String methodName, {bool forStats = false}) {
    final list = forStats ? _statsSelectedPaymentMethods : _calendarSelectedPaymentMethods;
    if (list.contains(methodName)) {
      list.remove(methodName);
    } else {
      list.add(methodName);
    }
    if (!forStats) {
      _storage.write(key: _calFilterMethodsKey, value: json.encode(list));
    }
    notifyListeners();
  }

  /// 모든 필터 설정을 초기화합니다.
  void clearFilters({bool forStats = false}) {
    if (forStats) {
      _statsSelectedType = null;
      _statsSelectedCategories.clear();
      _statsSelectedRelations.clear();
      _statsSelectedPaymentMethods.clear();
    } else {
      _calendarSelectedType = null;
      _calendarSelectedCategories.clear();
      _calendarSelectedRelations.clear();
      _calendarSelectedPaymentMethods.clear();
      _storage.delete(key: _calFilterTypeKey);
      _storage.delete(key: _calFilterCatsKey);
      _storage.delete(key: _calFilterRelsKey);
      _storage.delete(key: _calFilterMethodsKey);
    }
    notifyListeners();
  }

  /// 로그아웃이나 데이터 초기화 시 모든 메모리상의 데이터를 비웁니다.
  void clearData() {
    _transactions.clear();
    _allCategories.clear();
    _customRelations.clear();
    _statistics = null;
    _recurringTransactions.clear();
    _paymentMethods.clear();
    // 필터 초기화
    _calendarSelectedType = null;
    _calendarSelectedCategories.clear();
    _calendarSelectedRelations.clear();
    _calendarSelectedPaymentMethods.clear();
    _statsSelectedType = null;
    _statsSelectedCategories.clear();
    _statsSelectedRelations.clear();
    _statsSelectedPaymentMethods.clear();
    notifyListeners();
  }

  // --- 통계용 화면 필터 상태 (메모리에만 유지) ---
  TransactionType? _statsSelectedType;
  final List<String> _statsSelectedCategories = [];
  final List<String> _statsSelectedRelations = [];
  final List<String> _statsSelectedPaymentMethods = [];

  TransactionType? get statsSelectedType => _statsSelectedType;
  List<String> get statsSelectedCategories => _statsSelectedCategories;
  List<String> get statsSelectedRelations => _statsSelectedRelations;
  List<String> get statsSelectedPaymentMethods => _statsSelectedPaymentMethods;
}
