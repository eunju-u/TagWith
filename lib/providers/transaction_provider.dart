import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_strings.dart';
import '../data/models.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Relation> _customRelations = [];
  List<Relation> get customRelations => _customRelations;
  Statistics? _statistics;
  Statistics? get statistics => _statistics;
  
  final _storage = const FlutterSecureStorage();
  static const String _budgetKey = 'monthly_budget';
  static const String _calFilterTypeKey = 'cal_filter_type';
  static const String _calFilterCatsKey = 'cal_filter_cats';
  static const String _calFilterRelsKey = 'cal_filter_rels';

  double _monthlyBudget = 1000000.0; // 기본 예산 100만원
  double get monthlyBudget => _monthlyBudget;

  TransactionProvider() {
    _loadBudget();
    _loadFilters();
  }

  Future<void> _loadBudget() async {
    final savedBudget = await _storage.read(key: _budgetKey);
    if (savedBudget != null) {
      _monthlyBudget = double.tryParse(savedBudget) ?? 1000000.0;
      notifyListeners();
    }
  }

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
    notifyListeners();
  }

  Future<void> updateMonthlyBudget(double newBudget) async {
    _monthlyBudget = newBudget;
    await _storage.write(key: _budgetKey, value: newBudget.toString());
    notifyListeners();
  }

  Future<void> addCustomRelation(String name) async {
    if (name.trim().isEmpty) return;
    if (_customRelations.any((r) => r.name == name)) return;
    
    final newTag = await _service.createTag(name);
    if (newTag != null) {
      _customRelations.add(newTag);
      notifyListeners();
    }
  }

  // 사용자 전용 카테고리 추가
  Future<bool> addCustomCategory(Category category) async {
    final newCategory = await _service.createUserCategory(category);
    if (newCategory != null) {
      _allCategories.add(newCategory);
      notifyListeners();
      return true;
    }
    return false;
  }

  // 사용자 전용 카테고리 수정
  Future<bool> updateCustomCategory(Category category) async {
    final updated = await _service.updateUserCategory(category);
    if (updated != null) {
      final index = _allCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _allCategories[index] = updated;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // 사용자 전용 카테고리 삭제
  Future<bool> deleteCustomCategory(String categoryId) async {
    final success = await _service.deleteUserCategory(categoryId);
    if (success) {
      _allCategories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    }
    return success;
  }

  Future<void> loadStatistics({int? year, int? month}) async {
    _statistics = await _service.getStatistics(year: year, month: month);
    notifyListeners();
  }

  List<Transaction> _transactions = [];

  List<Category> _allCategories = [];
  List<Category> get allCategories => _allCategories;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    // 병렬로 데이터 로드
    final results = await Future.wait([
      _service.getTransactions(),
      _service.getCategories(),
      _service.getUserCategories(), // 유저별 카테고리 추가
      _service.getTags(),
      _service.getStatistics(year: DateTime.now().year, month: DateTime.now().month),
    ]);

    _transactions = results[0] as List<Transaction>;
    final globalCats = results[1] as List<Category>;
    final userCats = results[2] as List<Category>;
    _allCategories = [...globalCats, ...userCats]; // 전역(정렬됨) + 유저(정렬됨) 카테고리 순서대로 병합
    
    // 내역의 카테고리를 실제 카테고리 리스트와 매핑 (ID 일치를 위해)
    _transactions = _transactions.map((t) {
      final realCat = _allCategories.firstWhere(
        (c) => c.name == t.category.name,
        orElse: () => t.category,
      );
      return t.copyWith(category: realCat);
    }).toList();
    _customRelations = results[3] as List<Relation>;
    _statistics = results[4] as Statistics?;
    
    _isLoading = false;
    notifyListeners();
  }

  List<Transaction> get calendarFilteredTransactions {
     return _transactions.where((t) {
      final matchesType = _calendarSelectedType == null || t.type == _calendarSelectedType;
      final matchesCategory = _calendarSelectedCategories.isEmpty || _calendarSelectedCategories.contains(t.category.id);
      final matchesRelation = _calendarSelectedRelations.isEmpty || t.relations.any((r) => _calendarSelectedRelations.contains(r.id));
      return matchesType && matchesCategory && matchesRelation;
    }).toList();
  }

  List<Transaction> get statsFilteredTransactions {
    return _transactions.where((t) {
      final matchesType = _statsSelectedType == null || t.type == _statsSelectedType;
      final matchesCategory = _statsSelectedCategories.isEmpty || _statsSelectedCategories.contains(t.category.id);
      final matchesRelation = _statsSelectedRelations.isEmpty || t.relations.any((r) => _statsSelectedRelations.contains(r.id));
      return matchesType && matchesCategory && matchesRelation;
    }).toList();
  }

  // Calendar Filter State
  TransactionType? _calendarSelectedType;
  final List<String> _calendarSelectedCategories = [];
  final List<String> _calendarSelectedRelations = [];

  TransactionType? get calendarSelectedType => _calendarSelectedType;
  List<String> get calendarSelectedCategories => _calendarSelectedCategories;
  List<String> get calendarSelectedRelations => _calendarSelectedRelations;

  // Stats Filter State
  TransactionType? _statsSelectedType;
  final List<String> _statsSelectedCategories = [];
  final List<String> _statsSelectedRelations = [];

  TransactionType? get statsSelectedType => _statsSelectedType;
  List<String> get statsSelectedCategories => _statsSelectedCategories;
  List<String> get statsSelectedRelations => _statsSelectedRelations;
  
  bool get hasCalendarFilters => _calendarSelectedType != null || _calendarSelectedCategories.isNotEmpty || _calendarSelectedRelations.isNotEmpty;
  bool get hasStatsFilters => _statsSelectedType != null || _statsSelectedCategories.isNotEmpty || _statsSelectedRelations.isNotEmpty;

  void setTypeFilter(TransactionType? type, {bool forStats = false}) {
    if (forStats) {
      _statsSelectedType = type;
    } else {
      _calendarSelectedType = type;
      _storage.write(key: _calFilterTypeKey, value: type?.name);
    }
    notifyListeners();
  }

  void toggleCategoryFilter(String categoryId, {bool forStats = false}) {
    final list = forStats ? _statsSelectedCategories : _calendarSelectedCategories;
    if (list.contains(categoryId)) {
      list.remove(categoryId);
    } else {
      list.add(categoryId);
    }
    if (!forStats) {
      _storage.write(key: _calFilterCatsKey, value: json.encode(_calendarSelectedCategories));
    }
    notifyListeners();
  }

  void toggleRelationFilter(String relationId, {bool forStats = false}) {
    final list = forStats ? _statsSelectedRelations : _calendarSelectedRelations;
    if (list.contains(relationId)) {
      list.remove(relationId);
    } else {
      list.add(relationId);
    }
    if (!forStats) {
      _storage.write(key: _calFilterRelsKey, value: json.encode(_calendarSelectedRelations));
    }
    notifyListeners();
  }

  void clearFilters({bool forStats = false}) {
    if (forStats) {
      _statsSelectedType = null;
      _statsSelectedCategories.clear();
      _statsSelectedRelations.clear();
    } else {
      _calendarSelectedType = null;
      _calendarSelectedCategories.clear();
      _calendarSelectedRelations.clear();
      _storage.delete(key: _calFilterTypeKey);
      _storage.delete(key: _calFilterCatsKey);
      _storage.delete(key: _calFilterRelsKey);
    }
    notifyListeners();
  }

  List<Transaction> getTransactionsByDate(DateTime date) {
    return calendarFilteredTransactions.where((t) => 
      t.date.year == date.year && 
      t.date.month == date.month && 
      t.date.day == date.day
    ).toList();
  }

  double getTotalIncomeByDate(DateTime date) {
    return getTransactionsByDate(date)
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseByDate(DateTime date) {
    return getTransactionsByDate(date)
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalIncomeByMonth(DateTime month) {
    return calendarFilteredTransactions
        .where((t) => t.type == TransactionType.income && t.date.year == month.year && t.date.month == month.month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseByMonth(DateTime month) {
    return calendarFilteredTransactions
        .where((t) => t.type == TransactionType.expense && t.date.year == month.year && t.date.month == month.month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalIncomeByYear(int year) {
    return calendarFilteredTransactions
        .where((t) => t.type == TransactionType.income && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenseByYear(int year) {
    return calendarFilteredTransactions
        .where((t) => t.type == TransactionType.expense && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategorySpending(TransactionType type, {bool forStats = false, int? year, int? month}) {
    final map = <String, double>{};
    var transactions = forStats ? statsFilteredTransactions : calendarFilteredTransactions;
    
    // 기간 필터링 추가
    if (year != null || month != null) {
      transactions = transactions.where((t) {
        bool matches = true;
        if (year != null) matches = matches && t.date.year == year;
        if (month != null) matches = matches && t.date.month == month;
        return matches;
      }).toList();
    }

    for (var t in transactions.where((t) => t.type == type)) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    return map;
  }

  Map<PaymentMethod, double> getPaymentMethodSpending({bool forStats = true, int? year, int? month}) {
    final map = <PaymentMethod, double>{};
    var transactions = forStats ? statsFilteredTransactions : calendarFilteredTransactions;
    
    // 기간 필터링 추가
    if (year != null || month != null) {
      transactions = transactions.where((t) {
        bool matches = true;
        if (year != null) matches = matches && t.date.year == year;
        if (month != null) matches = matches && t.date.month == month;
        return matches;
      }).toList();
    }
    
    // Initialize all methods with 0 to ensure they appear in UI
    for (var method in PaymentMethod.values) {
      map[method] = 0;
    }

    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> getTagSpending({bool forStats = true, int? year, int? month}) {
    final map = <String, double>{};
    var transactions = forStats ? statsFilteredTransactions : calendarFilteredTransactions;
    
    // 기간 필터링 추가
    if (year != null || month != null) {
      transactions = transactions.where((t) {
        bool matches = true;
        if (year != null) matches = matches && t.date.year == year;
        if (month != null) matches = matches && t.date.month == month;
        return matches;
      }).toList();
    }
    
    // 수입/지출 상관없이 모든 태그 통계를 집계하여 사용자 혼란 방지
    for (var t in transactions) { 
      for (var rel in t.relations) {
        map[rel.name] = (map[rel.name] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // 달별 수입/지출 트렌드 데이터 (가변 기간)
  Map<DateTime, Map<String, double>> getMonthlyTrend({DateTime? rootDate, int months = 6}) {
    final baseDate = rootDate ?? DateTime.now();
    final result = <DateTime, Map<String, double>>{};
    
    for (int i = 0; i < months; i++) {
      // 지정된 날짜부터 거꾸로 계산
      final monthDate = DateTime(baseDate.year, baseDate.month - i, 1);
      final monthTransactions = _transactions.where((t) => t.date.year == monthDate.year && t.date.month == monthDate.month);
      
      final income = monthTransactions.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
      final expense = monthTransactions.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
      
      result[monthDate] = {'income': income, 'expense': expense};
    }
    // 날짜별 오름차순 정렬
    return Map.fromEntries(result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }



  double getTotalByMethod(TransactionType type, List<PaymentMethod> methods, {int? year, DateTime? month}) {
    return calendarFilteredTransactions.where((t) {
      final matchesType = t.type == type;
      final matchesMethod = methods.contains(t.paymentMethod);
      bool matchesPeriod = true;
      if (year != null) {
        matchesPeriod = t.date.year == year;
      } else if (month != null) {
        matchesPeriod = t.date.year == month.year && t.date.month == month.month;
      }
      return matchesType && matchesMethod && matchesPeriod;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<bool> addTransaction(Transaction transaction) async {
    final savedTransaction = await _service.createTransaction(transaction);
    if (savedTransaction != null) {
      final hydrated = savedTransaction.copyWith(
        category: _allCategories.firstWhere((c) => c.name == savedTransaction.category.name, orElse: () => savedTransaction.category),
      );
      _transactions.add(hydrated);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(String id) async {
    final success = await _service.deleteTransaction(id);
    if (success) {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    final updated = await _service.updateTransaction(transaction);
    if (updated != null) {
      final hydrated = updated.copyWith(
        category: _allCategories.firstWhere((c) => c.name == updated.category.name, orElse: () => updated.category),
      );
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = hydrated;
        // 통계 데이터도 다시 로드 (금액 등이 바뀌었을 수 있으므로)
        await loadStatistics(year: transaction.date.year, month: transaction.date.month);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 모든 로컬 데이터 초기화 (로그아웃/회원탈퇴 시 호출)
  Future<void> clearData() async {
    _transactions = [];
    _allCategories = [];
    _customRelations = [];
    _statistics = null;
    _isLoading = false;
    
    // 필터 초기화
    _calendarSelectedType = null;
    _calendarSelectedCategories.clear();
    _calendarSelectedRelations.clear();
    _statsSelectedType = null;
    _statsSelectedCategories.clear();
    _statsSelectedRelations.clear();
    
    // 예산 초기화 및 저장소 삭제
    _monthlyBudget = 1000000.0;
    await _storage.delete(key: _budgetKey);
    
    notifyListeners();
  }
}
