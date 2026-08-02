import 'package:uuid/uuid.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String action;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  ActivityLog({
    String? id,
    required this.userId,
    required this.action,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ActivityLog copyWith({
    String? id,
    String? userId,
    String? action,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': true,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as String? ?? const Uuid().v4(),
      userId: map['userId'] as String? ?? 'guest',
      action: map['action'] as String? ?? 'app_open',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }
}
