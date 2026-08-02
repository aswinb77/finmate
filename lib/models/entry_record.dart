import 'dart:convert';
import 'package:uuid/uuid.dart';

class EntryRecord {
  final String id;
  final String userId;
  final String type; // "expense", "chat_message", "goal"
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  EntryRecord({
    String? id,
    required this.userId,
    required this.type,
    required this.payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  EntryRecord copyWith({
    String? id,
    String? userId,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return EntryRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'payload': jsonEncode(payload),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': true,
    };
  }

  factory EntryRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    if (map['payload'] is String) {
      try {
        parsedPayload = jsonDecode(map['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    } else if (map['payload'] is Map) {
      parsedPayload = Map<String, dynamic>.from(map['payload'] as Map);
    }

    return EntryRecord(
      id: map['id'] as String? ?? const Uuid().v4(),
      userId: map['userId'] as String? ?? 'guest',
      type: map['type'] as String? ?? 'entry',
      payload: parsedPayload,
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }
}
