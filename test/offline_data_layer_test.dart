import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/models/app_user.dart';
import 'package:finmate/models/entry_record.dart';
import 'package:finmate/models/bug_report.dart';
import 'package:finmate/models/expense.dart';
import 'package:finmate/models/goal.dart';

void main() {
  group('Offline Data Layer & Models Tests', () {
    test('AppUser serialization and admin role check', () {
      final user = AppUser(
        uid: 'user_123',
        email: 'varientLoki7@gmail.com',
        name: 'Loki',
        role: 'admin',
      );

      expect(user.isAdmin, isTrue);

      final map = user.toMap();
      expect(map['email'], equals('varientLoki7@gmail.com'));
      expect(map['role'], equals('admin'));

      final deserialized = AppUser.fromMap(map);
      expect(deserialized.uid, equals('user_123'));
      expect(deserialized.isAdmin, isTrue);
    });

    test('EntryRecord creation with UUID and payload serialization', () {
      final expense = Expense(
        name: 'Cutting Chai',
        amount: 15,
        category: 'Food',
        emoji: '☕',
        color: const Color(0xFFA8CCAC),
      );

      final entry = EntryRecord(
        userId: 'user_123',
        type: 'expense',
        payload: expense.toMap(),
        synced: false,
      );

      expect(entry.id, isNotEmpty);
      expect(entry.synced, isFalse);
      expect(entry.payload['name'], equals('Cutting Chai'));

      final firestoreMap = entry.toFirestoreMap();
      expect(firestoreMap['synced'], isTrue);
    });

    test('BugReport serialization and status updates', () {
      final bug = BugReport(
        userId: 'user_123',
        userEmail: 'varientLoki7@gmail.com',
        description: 'Test bug description',
        status: 'open',
      );

      expect(bug.status, equals('open'));
      expect(bug.synced, isFalse);

      final updated = bug.copyWith(status: 'resolved', synced: true);
      expect(updated.status, equals('resolved'));
      expect(updated.synced, isTrue);
    });

    test('Goal and GoalMilestones serialization', () {
      final goal = Goal.defaultGoaTrip();
      final map = goal.toMap();

      expect(map['name'], equals('Goa Trip'));
      expect(map['targetAmount'], equals(15000));

      final restored = Goal.fromMap(map);
      expect(restored.name, equals('Goa Trip'));
      expect(restored.milestones.length, equals(goal.milestones.length));
    });
  });
}
