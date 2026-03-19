import 'package:flutter/material.dart';
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

  Future<void> addCustomRelation(String name) async {
    if (name.trim().isEmpty) return;
    if (_customRelations.any((r) => r.name == name)) return;
    
    final newTag = await _service.createTag(name);
    if (newTag != null) {
      _customRelations.add(newTag);
      notifyListeners();
    }
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
      _service.getTags(),
      _service.getStatistics(year: DateTime.now().year, month: DateTime.now().month),
    ]);

    _transactions = results[0] as List<Transaction>;
    _allCategories = results[1] as List<Category>;
    _customRelations = results[2] as List<Relation>;
    _statistics = results[3] as Statistics?;
    
    // 카테고리가 비어있을 경우 기본값 세팅 (서버에서 아직 안 온 경우를 대비)
    if (_allCategories.isEmpty) {
      _allCategories = [
        Category(id: '1', name: '식비', icon: Icons.restaurant, color: Colors.orange),
        Category(id: '2', name: '카페/간식', icon: Icons.coffee, color: Colors.brown),
        Category(id: '3', name: '수입', icon: Icons.account_balance_wallet, color: Colors.blue),
        Category(id: '4', name: '교통', icon: Icons.directions_bus, color: Colors.teal),
        Category(id: '5', name: '생활/쇼핑', icon: Icons.shopping_bag, color: Colors.purple),
      ];
    }
    
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

  void setTypeFilter(TransactionType? type, {bool forStats = false}) {
    if (forStats) {
      _statsSelectedType = type;
    } else {
      _calendarSelectedType = type;
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
    notifyListeners();
  }

  void toggleRelationFilter(String relationId, {bool forStats = false}) {
    final list = forStats ? _statsSelectedRelations : _calendarSelectedRelations;
    if (list.contains(relationId)) {
      list.remove(relationId);
    } else {
      list.add(relationId);
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
      _transactions.add(savedTransaction);
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
}
