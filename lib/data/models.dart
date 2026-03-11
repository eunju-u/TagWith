import 'package:flutter/material.dart';

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
}

class Relation {
  final String id;
  final String name;

  Relation({
    required this.id,
    required this.name,
  });
}

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String description;
  final TransactionType type;
  final Category category;
  final List<Relation> relations;
  final PaymentMethod paymentMethod;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
    required this.category,
    required this.relations,
    required this.paymentMethod,
  });

  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? description,
    TransactionType? type,
    Category? category,
    List<Relation>? relations,
    PaymentMethod? paymentMethod,
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
    );
  }
}
