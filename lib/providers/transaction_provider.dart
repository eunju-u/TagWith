import 'package:flutter/material.dart';
import '../data/models.dart';

class TransactionProvider with ChangeNotifier {
  final List<Relation> _customRelations = [
    Relation(id: '1', name: '친구1'),
    Relation(id: '2', name: '직장동료'),
    Relation(id: '3', name: '부모님'),
  ];

  List<Relation> get customRelations => _customRelations;

  void addCustomRelation(String name) {
    if (name.trim().isEmpty) return;
    if (_customRelations.any((r) => r.name == name)) return;
    
    final newRelation = Relation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _customRelations.add(newRelation);
    notifyListeners();
  }

  final List<Transaction> _transactions = [
    // Mock Data
    Transaction(
      id: '1',
      date: DateTime.now(),
      amount: 15000,
      description: '점심 (김치찌개)',
      type: TransactionType.expense,
      category: Category(id: '1', name: '식비', icon: Icons.restaurant, color: Colors.orange),
      relations: [Relation(id: '1', name: '친구1')],
      paymentMethod: PaymentMethod.checkCard,
    ),
    Transaction(
      id: '2',
      date: DateTime.now(),
      amount: 4500,
      description: '아메리카노',
      type: TransactionType.expense,
      category: Category(id: '2', name: '카페/간식', icon: Icons.coffee, color: Colors.brown),
      relations: [Relation(id: '2', name: '직장동료')],
      paymentMethod: PaymentMethod.creditCard,
    ),
    Transaction(
      id: '3',
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 50000,
      description: '용돈',
      type: TransactionType.income,
      category: Category(id: '3', name: '수입', icon: Icons.account_balance_wallet, color: Colors.blue),
      relations: [Relation(id: '3', name: '부모님')],
      paymentMethod: PaymentMethod.cash,
    ),
    Transaction(
      id: '4',
      date: DateTime.now().subtract(const Duration(days: 2)),
      amount: 12000,
      description: '택시비',
      type: TransactionType.expense,
      category: Category(id: '4', name: '교통', icon: Icons.directions_bus, color: Colors.teal),
      relations: [Relation(id: '4', name: '나')],
      paymentMethod: PaymentMethod.checkCard,
    ),
    Transaction(
      id: '5',
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 85000,
      description: '친구 생일 선물',
      type: TransactionType.expense,
      category: Category(id: '5', name: '생활/쇼핑', icon: Icons.shopping_bag, color: Colors.purple),
      relations: [Relation(id: '5', name: '친구2')],
      paymentMethod: PaymentMethod.creditCard,
    ),
  ];

  final List<Category> _allCategories = [
    Category(id: '1', name: '식비', icon: Icons.restaurant, color: Colors.orange),
    Category(id: '2', name: '카페/간식', icon: Icons.coffee, color: Colors.brown),
    Category(id: '3', name: '수입', icon: Icons.account_balance_wallet, color: Colors.blue),
    Category(id: '4', name: '교통', icon: Icons.directions_bus, color: Colors.teal),
    Category(id: '5', name: '생활/쇼핑', icon: Icons.shopping_bag, color: Colors.purple),
  ];

  List<Category> get allCategories => _allCategories;

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

  Map<String, double> getCategorySpending(TransactionType type, {bool forStats = false}) {
    final map = <String, double>{};
    final transactions = forStats ? statsFilteredTransactions : calendarFilteredTransactions;
    for (var t in transactions.where((t) => t.type == type)) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    return map;
  }

  Map<PaymentMethod, double> getPaymentMethodSpending({bool forStats = true}) {
    final map = <PaymentMethod, double>{};
    final transactions = forStats ? statsFilteredTransactions : calendarFilteredTransactions;
    
    // Initialize all methods with 0 to ensure they appear in UI
    for (var method in PaymentMethod.values) {
      map[method] = 0;
    }

    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + t.amount;
    }
    return map;
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

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }
}
