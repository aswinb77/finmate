import 'package:flutter/material.dart';

/// Mood values for the "Worth it?" feature
/// 0 = 😍 Worth it, 1 = 😐 Meh, 2 = 😩 Regret

// ── Chat message type ─────────────────────────────────────────────────────
/// Controls how the chat bubble renderer displays this message.
enum ChatMessageType {
  normal,          // plain text bubble (default)
  searchResults,   // inline transaction list rendered inside the bubble
  categoryChips,   // log confirmation + tappable category-correction chips
  undoPrompt,      // interactive undo confirmation with Yes / No option buttons
}

// ── Search result row ─────────────────────────────────────────────────────
class SearchResultRow {
  final String name;
  final String date;
  final int amount;
  const SearchResultRow({required this.name, required this.date, required this.amount});
}

// ── Category chip option ──────────────────────────────────────────────────
class CategoryChipOption {
  final String label;
  final String emoji;
  const CategoryChipOption({required this.label, required this.emoji});
}

class Expense {
  final String id;
  final String name;
  final int amount;
  final String category;
  final String emoji;
  final Color color;
  final DateTime timestamp;
  int? mood; // 0 = loved, 1 = meh, 2 = regret
  final bool isEdited; // true when the amount was changed via "change last to"

  Expense({
    String? id,
    required this.name,
    required this.amount,
    required this.category,
    required this.emoji,
    required this.color,
    DateTime? timestamp,
    this.mood,
    this.isEdited = false,
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
    bool? isEdited,
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
      isEdited: isEdited ?? this.isEdited,
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
      'colorValue': color.toARGB32(),
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'isEdited': isEdited,
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
      isEdited: map['isEdited'] as bool? ?? false,
    );
  }

  static const moodEmojis = ['😍', '😐', '😩'];
  static const moodLabels = ['Worth it', 'Meh', 'Regret'];
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;

  // Payload for searchResults bubbles
  final List<SearchResultRow>? searchResults;

  // Payload for categoryChips bubbles — the expense that was just logged
  final Expense? loggedExpense;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.normal,
    this.searchResults,
    this.loggedExpense,
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
