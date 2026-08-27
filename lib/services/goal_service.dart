import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../models/entry_record.dart';
import '../models/activity_log.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';
import 'sync_service.dart';

class GoalService extends ChangeNotifier {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal() {
    _auth.addListener(_onAuthChanged);
    _sync.addListener(_onSyncChanged);
  }

  void _onAuthChanged() {
    loadLocalGoal(forceReload: true);
  }

  void _onSyncChanged() {
    if (_sync.syncState == SyncState.idle) {
      loadLocalGoal(forceReload: true);
    }
  }

  final LocalStorageService _storage = LocalStorageService();
  final AuthService _auth = AuthService();
  final SyncService _sync = SyncService();

  Goal? _activeGoal;
  bool _loadedFromDb = false;

  Goal? get activeGoal => _activeGoal;
  bool get hasGoal => _activeGoal != null;

  Future<void> loadLocalGoal({bool forceReload = false}) async {
    if (_loadedFromDb && !forceReload) return;
    try {
      final userId = _auth.currentUser?.uid ?? 'guest_user';
      final records = await _storage.getEntriesForUser(userId);
      final goalRecords = records.where((r) => r.type == 'goal').toList();
      if (goalRecords.isNotEmpty) {
        _activeGoal = Goal.fromMap(goalRecords.first.payload);
      } else {
        _activeGoal = null;
      }
    } catch (e) {
      debugPrint('Error loading goal: $e');
    } finally {
      _loadedFromDb = true;
      notifyListeners();
    }
  }

  void setGoal(Goal goal) {
    _activeGoal = goal;
    notifyListeners();
    _persistGoal(goal);
  }

  void createGoal({
    required String name,
    required int targetAmount,
    required String targetDate,
    required String emoji,
    int initialSaved = 0,
    List<GoalMilestone>? milestones,
  }) {
    final ms = milestones ?? Goal.generateMilestones(name);
    final newGoal = Goal(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      targetAmount: targetAmount,
      currentAmount: initialSaved,
      targetDate: targetDate,
      milestones: ms,
    );
    _activeGoal = newGoal;
    notifyListeners();
    _persistGoal(newGoal);
    _logActivity('create_goal');
  }

  void addAmount(int amount) {
    if (_activeGoal != null) {
      _activeGoal!.currentAmount =
          (_activeGoal!.currentAmount + amount).clamp(0, _activeGoal!.targetAmount * 2);
      notifyListeners();
      _persistGoal(_activeGoal!);
      _logActivity('contribute_to_goal');
    }
  }

  void deleteGoal() {
    final goalId = _activeGoal?.id;
    _activeGoal = null;
    notifyListeners();
    _logActivity('delete_goal');
    if (goalId != null && goalId.isNotEmpty) {
      _storage.deleteEntry(goalId);
      if (!_auth.isGuest) {
        _sync.refreshUnsyncedCount();
        if (_sync.isOnline) {
          _sync.triggerSync();
        }
      }
    }
  }

  Future<void> _persistGoal(Goal goal) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final entry = EntryRecord(
      id: goal.id.isNotEmpty ? goal.id : const Uuid().v4(),
      userId: userId,
      type: 'goal',
      payload: goal.toMap(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );

    await _storage.saveEntry(entry);
    if (!_auth.isGuest) {
      _sync.refreshUnsyncedCount();
      if (_sync.isOnline) {
        _sync.triggerSync();
      }
    }
  }

  Future<void> _logActivity(String action) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final log = ActivityLog(
      userId: userId,
      action: action,
      createdAt: DateTime.now(),
      synced: false,
    );
    await _storage.saveActivityLog(log);
  }
}
