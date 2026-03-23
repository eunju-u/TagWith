import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, checkCard, creditCard }

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'],
      icon: _parseIcon(json['icon']),
      color: _parseColor(json['color']),
    );
  }

  static IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.coffee;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'directions_bus': return Icons.directions_bus;
      case 'shopping_bag': return Icons.shopping_bag;
      default: return Icons.category;
    }
  }

  static Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  factory Category.fromName(String name) {
    switch (name) {
      case '식비':
        return Category(id: '1', name: '식비', icon: Icons.restaurant, color: Colors.orange);
      case '카페/간식':
        return Category(id: '2', name: '카페/간식', icon: Icons.coffee, color: Colors.brown);
      case '수입':
        return Category(id: '3', name: '수입', icon: Icons.account_balance_wallet, color: Colors.blue);
      case '교통':
        return Category(id: '4', name: '교통', icon: Icons.directions_bus, color: Colors.teal);
      case '생활/쇼핑':
        return Category(id: '5', name: '생활/쇼핑', icon: Icons.shopping_bag, color: Colors.purple);
      case '기타':
        return Category(id: '6', name: '기타', icon: Icons.more_horiz, color: Colors.blueGrey);
      default:
        return Category(id: '0', name: name, icon: Icons.category, color: Colors.grey);
    }
  }
}

class Relation {
  final String id;
  final String name;

  Relation({
    required this.id,
    required this.name,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      id: json['id'].toString(),
      name: json['name'],
    );
  }

  factory Relation.fromTagName(String name) {
    return Relation(id: name, name: name);
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class Transaction {
  /// 내역의 고유 식별자 (ID)
  final String id;
  
  /// 거래가 발생한 날짜와 시간
  final DateTime date;
  
  /// 거래 금액
  final double amount;
  
  /// 거래에 대한 설명 (예: 맛있는 돈까스)
  final String description;
  
  /// 거래 유형 (수입: income, 지출: expense)
  final TransactionType type;
  
  /// 거래 카테고리 (식비, 교통, 수입 등)
  final Category category;
  
  /// 거래와 관련된 관계 또는 태그 목록 (예: 친구, 가족 등)
  final List<Relation> relations;
  
  /// 결제 수단 (현금, 체크카드, 신용카드)
  final PaymentMethod paymentMethod;
  
  /// 이미 저장된 내역인지 여부 (중복 체크 결과)
  final bool isDuplicate;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
    required this.category,
    required this.relations,
    required this.paymentMethod,
    this.isDuplicate = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // 서버 규격인 tags 필드로 통일
    final List<dynamic> tagData = (json['tags'] as List?) ?? [];
    
    return Transaction(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']).toLocal(),
      amount: json['amount'].toDouble(),
      description: json['description'] ?? '',
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category_detail'] != null 
          ? Category.fromJson(json['category_detail']) 
          : Category.fromName(json['category'] ?? ''),
      relations: tagData.map((e) {
        if (e is Map<String, dynamic>) {
          return Relation.fromJson(e);
        }
        return Relation.fromTagName(e.toString());
      }).toList(),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      isDuplicate: json['is_duplicate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'category': category.name,
      'date': DateFormat('yyyy-MM-dd').format(date), // 사용자 타임존 기준 날짜만 전송하여 오차 방지
      'type': type == TransactionType.income ? 'income' : 'expense',
      'tags': relations.map((r) => r.name).toList(), // 서버 최종 표준인 tags 사용
      'payment_method': _paymentMethodToString(paymentMethod),
    };
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'cash';
      case PaymentMethod.checkCard: return 'checkCard';
      case PaymentMethod.creditCard: return 'creditCard';
    }
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method) {
      case 'cash': return PaymentMethod.cash;
      case 'checkCard': return PaymentMethod.checkCard;
      case 'creditCard': return PaymentMethod.creditCard;
      default: return PaymentMethod.checkCard;
    }
  }

  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? description,
    TransactionType? type,
    Category? category,
    List<Relation>? relations,
    PaymentMethod? paymentMethod,
    bool? isDuplicate,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      relations: relations ?? this.relations,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}

// 통계 데이터 모델 추가
class Statistics {
  final double totalIncome;
  final double totalExpense;
  final double lastMonthExpense;
  final double dailyAverageExpense; // 추가: 일일 평균 지출
  final String mostSpentWeekday;   // 추가: 최다 지출 요일
  final List<CategorySpending> categorySpending;
  final List<TagSpending> tagSpending;
  final List<MonthlyTrend> monthlyTrend;

  Statistics({
    required this.totalIncome,
    required this.totalExpense,
    required this.lastMonthExpense,
    required this.dailyAverageExpense,
    required this.mostSpentWeekday,
    required this.categorySpending,
    required this.tagSpending,
    required this.monthlyTrend,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      lastMonthExpense: (json['last_month_expense'] as num?)?.toDouble() ?? 0.0,
      dailyAverageExpense: (json['daily_average_expense'] as num?)?.toDouble() ?? 0.0,
      mostSpentWeekday: json['most_spent_weekday'] ?? '없음',
      categorySpending: (json['category_spending'] as List?)
          ?.map((e) => CategorySpending.fromJson(e))
          .toList() ?? [],
      tagSpending: (json['tag_spending'] as List?)
          ?.map((e) => TagSpending.fromJson(e))
          .toList() ?? [],
      monthlyTrend: (json['monthly_trend'] as List?)
          ?.map((e) => MonthlyTrend.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CategorySpending {
  final String name;
  final double amount;

  CategorySpending({required this.name, required this.amount});

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TagSpending {
  final String name;
  final double amount;

  TagSpending({required this.name, required this.amount});

  factory TagSpending.fromJson(Map<String, dynamic> json) {
    return TagSpending(
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyTrend {
  final String date;
  final double income;
  final double expense;

  MonthlyTrend({required this.date, required this.income, required this.expense});

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      date: json['date'] ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Receipt {
  final double amount;
  final String description;
  final String date;
  final String categorySuggestion;
  final bool isDuplicate;
  final PaymentMethod paymentMethod;

  Receipt({
    required this.amount,
    required this.description,
    required this.date,
    required this.categorySuggestion,
    this.isDuplicate = false,
    this.paymentMethod = PaymentMethod.checkCard,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final existing = json['existing_transaction'];
    final isDuplicate = existing != null && (existing is List ? existing.isNotEmpty : true);
    
    return Receipt(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      categorySuggestion: json['category_suggestion'] ?? '',
      isDuplicate: isDuplicate,
      paymentMethod: Transaction._parsePaymentMethod(json['payment_method']),
    );
  }
}
