import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_strings.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, checkCard, creditCard }

class Category {
  final String id;
  final String name;
  final String icon; // Icon name (e.g., 'restaurant') or Emoji sequence
  final Color color;
  final int order;
  final String? userId;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.order = 0,
    this.userId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      color: _parseColor(json['color']),
      order: json['order'] ?? 0,
      userId: json['user_id']?.toString(),
    );
  }

  // Returns IconData if it's a known identifier, otherwise null
  IconData? get iconData {
    switch (icon) {
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.coffee;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'directions_bus': return Icons.directions_bus;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'home': return Icons.home;
      case 'school': return Icons.school;
      case 'medical_services': return Icons.medical_services;
      case 'phone_android': return Icons.phone_android;
      case 'sports_esports': return Icons.sports_esports;
      case 'fitness_center': return Icons.fitness_center;
      case 'movie': return Icons.movie;
      case 'flight': return Icons.flight_takeoff;
      case 'pets': return Icons.pets;
      case 'category': return Icons.category;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'celebration': return Icons.celebration;
      case 'theater_comedy': return Icons.theater_comedy;
      case 'brush': return Icons.brush;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'vpn_key': return Icons.vpn_key;
      case 'lightbulb': return Icons.lightbulb;
      case 'more_horiz':
      case 'more_horizontal': return Icons.more_horiz;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'local_bar': return Icons.local_bar;
      case 'subscriptions': return Icons.subscriptions;
      case 'child_care': return Icons.child_care;
      case 'bolt': return Icons.bolt;
      case 'description': return Icons.description;
      default: return null;
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
      case AppStrings.incomeLabel:
        return Category(id: 'income', name: AppStrings.incomeLabel, icon: 'account_balance_wallet', color: Colors.blue);
      case AppStrings.categoryTransferFinance:
        return Category(id: 'finance', name: AppStrings.categoryTransferFinance, icon: 'swap_horiz', color: Colors.indigo);
      case AppStrings.categoryFood:
        return Category(id: 'food', name: AppStrings.categoryFood, icon: 'restaurant', color: Colors.orange);
      case AppStrings.categoryCafe:
        return Category(id: 'cafe', name: AppStrings.categoryCafe, icon: 'coffee', color: Colors.brown);
      case AppStrings.categoryLiquorEntertainment:
        return Category(id: 'entertainment', name: AppStrings.categoryLiquorEntertainment, icon: 'local_bar', color: Colors.redAccent);
      case AppStrings.categoryShopping:
        return Category(id: 'shopping', name: AppStrings.categoryShopping, icon: 'shopping_bag', color: Colors.purple);
      case AppStrings.categoryHobbyLeisure:
        return Category(id: 'hobby', name: AppStrings.categoryHobbyLeisure, icon: 'sports_esports', color: Colors.pink);
      case AppStrings.categoryTravel:
        return Category(id: 'travel', name: AppStrings.categoryTravel, icon: 'flight', color: Colors.lightBlue);
      case AppStrings.categoryTransport:
        return Category(id: 'transport', name: AppStrings.categoryTransport, icon: 'directions_bus', color: Colors.teal);
      case AppStrings.categoryHousing:
        return Category(id: 'housing', name: AppStrings.categoryHousing, icon: 'home', color: Colors.deepOrange);
      case AppStrings.categoryCommunication:
        return Category(id: 'communication', name: AppStrings.categoryCommunication, icon: 'phone_android', color: Colors.cyan);
      case AppStrings.categoryMedicalHealth:
        return Category(id: 'medical', name: AppStrings.categoryMedicalHealth, icon: 'medical_services', color: Colors.red);
      case AppStrings.categoryBeauty:
        return Category(id: 'beauty', name: AppStrings.categoryBeauty, icon: 'brush', color: Colors.pinkAccent);
      case AppStrings.categoryInsuranceTax:
        return Category(id: 'tax', name: AppStrings.categoryInsuranceTax, icon: 'description', color: Colors.blueGrey);
      case AppStrings.categoryEducation:
        return Category(id: 'education', name: AppStrings.categoryEducation, icon: 'school', color: Colors.indigoAccent);
      case AppStrings.categoryCelebration:
        return Category(id: 'celebration', name: AppStrings.categoryCelebration, icon: 'celebration', color: Colors.orangeAccent);
      case AppStrings.categoryCondolence:
        return Category(id: 'condolence', name: AppStrings.categoryCondolence, icon: 'more_horiz', color: Colors.grey);
      case AppStrings.categoryDonation:
        return Category(id: 'donation', name: AppStrings.categoryDonation, icon: 'card_giftcard', color: Colors.amber);
      case AppStrings.categoryParenting:
        return Category(id: 'parenting', name: AppStrings.categoryParenting, icon: 'child_care', color: Colors.greenAccent);
      case AppStrings.categoryPet:
        return Category(id: 'pet', name: AppStrings.categoryPet, icon: 'pets', color: Colors.lime);
      case AppStrings.categorySelfDev:
        return Category(id: 'selfdev', name: AppStrings.categorySelfDev, icon: 'bolt', color: Colors.deepPurple);
      case AppStrings.categorySubscription:
        return Category(id: 'subscription', name: AppStrings.categorySubscription, icon: 'subscriptions', color: Colors.blueAccent);
      case AppStrings.categoryLife:
        return Category(id: 'life', name: AppStrings.categoryLife, icon: 'shopping_cart', color: Colors.lightGreen);
      case AppStrings.categorySavings:
        return Category(id: 'savings', name: AppStrings.categorySavings, icon: '💰', color: Colors.green);
      case AppStrings.categoryWithdrawal:
        return Category(id: 'withdrawal', name: AppStrings.categoryWithdrawal, icon: '💸', color: Colors.red);
      case AppStrings.categoryCardPayment:
        return Category(id: 'cardpayment', name: AppStrings.categoryCardPayment, icon: '💳', color: Colors.deepPurple);
      case AppStrings.categoryMisc:
        return Category(id: 'misc', name: AppStrings.categoryMisc, icon: 'category', color: Colors.blueGrey);
      default:
        return Category(id: '0', name: name, icon: 'category', color: Colors.grey);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': _colorToHex(color),
      'order': order,
      'user_id': userId,
    };
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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
      mostSpentWeekday: json['most_spent_weekday'] ?? AppStrings.none,
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
