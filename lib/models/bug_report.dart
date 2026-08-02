import 'package:uuid/uuid.dart';

class BugReport {
  final String id;
  final String userId;
  final String userEmail;
  final String description;
  final String status; // "open", "in_progress", "resolved"
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  BugReport({
    String? id,
    required this.userId,
    required this.userEmail,
    required this.description,
    this.status = 'open',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  BugReport copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return BugReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'synced': true,
    };
  }

  factory BugReport.fromMap(Map<String, dynamic> map) {
    return BugReport(
      id: map['id'] as String? ?? const Uuid().v4(),
      userId: map['userId'] as String? ?? 'guest',
      userEmail: map['userEmail'] as String? ?? 'unknown@finmate.app',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
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
