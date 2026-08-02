import 'package:flutter/material.dart';

/// Mood values for the "Worth it?" feature
/// 0 = 😍 Worth it, 1 = 😐 Meh, 2 = 😩 Regret
class Expense {
  final String id;
  final String name;
  final int amount;
  final String category;
  final String emoji;
  final Color color;
  final DateTime timestamp;
  int? mood; // 0 = loved, 1 = meh, 2 = regret

  Expense({
    String? id,
    required this.name,
    required this.amount,
    required this.category,
    required this.emoji,
    required this.color,
    DateTime? timestamp,
    this.mood,
  })  : id = (id != null && id.isNotEmpty) ? id : UniqueKey().toString(),
        timestamp = timestamp ?? DateTime.now();

  Expense copyWith({
    String? id,
    String? name,
    int? amount,
    String? category,
    String? emoji,
    Color? color,
    DateTime? timestamp,
    int? mood,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
    );
  }

  bool get hasMood => mood != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'emoji': emoji,
      'colorValue': color.value,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Expense',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'Other',
      emoji: map['emoji'] as String? ?? '📦',
      color: map['colorValue'] != null
          ? Color(map['colorValue'] as int)
          : const Color(0xFFCCC0AE),
      timestamp: map['timestamp'] != null
          ? (DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      mood: map['mood'] as int?,
    );
  }

  static const moodEmojis = ['😍', '😐', '😩'];
  static const moodLabels = ['Worth it', 'Meh', 'Regret'];
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
