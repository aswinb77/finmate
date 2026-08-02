import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/entry_record.dart';
import '../models/bug_report.dart';
import '../models/activity_log.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';

enum SyncState { idle, syncing, offline, error }

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageService _storage = LocalStorageService();
  final AuthService _auth = AuthService();

  SyncState _syncState = SyncState.idle;
  bool _isOnline = true;
  String? _lastError;
  DateTime? _lastSyncedAt;
  int _unsyncedCount = 0;
  int _retryAttempt = 0;
  Timer? _backoffTimer;

  SyncState get syncState => _syncState;
  bool get isOnline => _isOnline;
  String? get lastError => _lastError;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get unsyncedCount => _unsyncedCount;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize() {
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        _onConnectivityChanged(online);
      },
    );
    refreshUnsyncedCount();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _backoffTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }
    notifyListeners();
    if (_isOnline) {
      triggerSync();
    }
  }

  void _onConnectivityChanged(bool online) {
    _isOnline = online;
    if (online) {
      _retryAttempt = 0;
      _backoffTimer?.cancel();
      triggerSync();
    } else {
      _syncState = SyncState.offline;
    }
    notifyListeners();
  }

  Future<void> refreshUnsyncedCount() async {
    try {
      final unsyncedEntries = await _storage.getUnsyncedEntries();
      final unsyncedBugs = await _storage.getUnsyncedBugReports();
      final unsyncedLogs = await _storage.getUnsyncedActivityLogs();

      _unsyncedCount =
          unsyncedEntries.length + unsyncedBugs.length + unsyncedLogs.length;
    } catch (e) {
      debugPrint('Error refreshing unsynced count: $e');
      _unsyncedCount = 0;
    }
    notifyListeners();
  }

  Future<void> triggerSync() async {
    // Skip sync for guest users — guests are local-only
    if (_auth.isGuest) {
      _syncState = SyncState.idle;
      notifyListeners();
      return;
    }

    if (!_isOnline || _syncState == SyncState.syncing) return;

    _syncState = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      await _performPushBatch();
      await _performPullUpdates();

      _syncState = SyncState.idle;
      _lastSyncedAt = DateTime.now();
      _retryAttempt = 0;
      await refreshUnsyncedCount();
    } catch (e) {
      debugPrint('Sync failed: $e');
      _syncState = SyncState.error;
      _lastError = e.toString();
      _scheduleExponentialBackoff();
    } finally {
      notifyListeners();
    }
  }

  void _scheduleExponentialBackoff() {
    _backoffTimer?.cancel();
    _retryAttempt++;

    // Backoff formula: min(60s, 2^(attempt-1) seconds + random jitter)
    final delaySeconds = min(60, pow(2, _retryAttempt - 1).toInt()) +
        Random().nextInt(2);

    debugPrint(
        'Scheduling sync retry attempt $_retryAttempt in $delaySeconds seconds...');

    _backoffTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isOnline) {
        triggerSync();
      }
    });
  }

  // ── PUSH: Local unsynced records -> Firestore batch ─────────────────────
  Future<void> _performPushBatch() async {
    final unsyncedEntries = await _storage.getUnsyncedEntries();
    final unsyncedBugs = await _storage.getUnsyncedBugReports();
    final unsyncedLogs = await _storage.getUnsyncedActivityLogs();

    final user = _auth.currentUser;
    if (user != null) {
      await _storage.saveUser(user.copyWith(lastActiveAt: DateTime.now()));
    }

    final isFirebaseInitialized = Firebase.apps.isNotEmpty;

    if (isFirebaseInitialized &&
        (unsyncedEntries.isNotEmpty ||
            unsyncedBugs.isNotEmpty ||
            unsyncedLogs.isNotEmpty ||
            user != null)) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Batch 1: Push Entries & update counter doc
      int newEntriesCount = 0;
      for (final entry in unsyncedEntries) {
        final updatedEntry = (entry.userId == 'guest' || entry.userId == 'guest_user') && user != null
            ? entry.copyWith(userId: user.uid)
            : entry;
        final docRef = firestore.collection('entries').doc(updatedEntry.id);
        batch.set(docRef, updatedEntry.toFirestoreMap(), SetOptions(merge: true));
        newEntriesCount++;
      }

      // Aggregate counter doc update (no full collection scan needed for admin)
      if (newEntriesCount > 0) {
        final counterRef = firestore.collection('counters').doc('entries_counter');
        batch.set(
          counterRef,
          {'count': FieldValue.increment(newEntriesCount)},
          SetOptions(merge: true),
        );
      }

      // Batch 2: Push Bug Reports
      for (final bug in unsyncedBugs) {
        final updatedBug = (bug.userId == 'guest' || bug.userId == 'guest_user') && user != null
            ? bug.copyWith(userId: user.uid, userEmail: user.email)
            : bug;
        final docRef = firestore.collection('bugReports').doc(updatedBug.id);
        batch.set(docRef, updatedBug.toFirestoreMap(), SetOptions(merge: true));
      }

      // Batch 3: Push Activity Logs
      for (final log in unsyncedLogs) {
        final updatedLog = (log.userId == 'guest' || log.userId == 'guest_user') && user != null
            ? ActivityLog(
                id: log.id,
                userId: user.uid,
                action: log.action,
                createdAt: log.createdAt,
                updatedAt: log.updatedAt,
                synced: log.synced,
              )
            : log;
        final docRef = firestore.collection('activityLogs').doc(updatedLog.id);
        batch.set(docRef, updatedLog.toFirestoreMap(), SetOptions(merge: true));
      }

      // Batch 4: Push User Profile
      if (user != null) {
        final userRef = firestore.collection('users').doc(user.uid);
        batch.set(userRef, user.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('Firestore sync pushed: $newEntriesCount entries, ${unsyncedBugs.length} bugs, ${unsyncedLogs.length} logs.');

      // Mark as locally synced ONLY AFTER successful batch commit
      await _storage.markEntriesSynced(unsyncedEntries.map((e) => e.id).toList());
      await _storage.markBugReportsSynced(unsyncedBugs.map((b) => b.id).toList());
      await _storage.markActivityLogsSynced(unsyncedLogs.map((l) => l.id).toList());
    }
  }

  // ── PULL: Firestore -> Local with last-write-wins ────────────────
  Future<void> _performPullUpdates() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final entriesSnapshot = await firestore.collection('entries').get();

      for (final doc in entriesSnapshot.docs) {
        final remoteRecord = EntryRecord.fromMap(doc.data());
        await _storage.upsertRemoteEntry(remoteRecord);
      }
    } catch (e) {
      debugPrint('Firestore pull failed: $e');
    }
  }

  // ── Aggregated Counter Document Fetch for Admin ────────────────────────
  Future<int> fetchAggregatedCounterDoc() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('counters')
            .doc('entries_counter')
            .get();
        if (doc.exists && doc.data() != null && doc.data()!['count'] != null) {
          return doc.data()!['count'] as int;
        }
      } catch (e) {
        debugPrint('Error reading counter doc: $e');
      }
    }
    return await _storage.getTotalEntryCount();
  }
}
