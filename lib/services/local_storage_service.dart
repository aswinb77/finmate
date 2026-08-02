import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/entry_record.dart';
import '../models/bug_report.dart';
import '../models/activity_log.dart';

/// Local storage service using SharedPreferences.
/// Works on all platforms (phone, web, desktop) without native binaries.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // SharedPreferences keys
  static const String _usersKey = 'local_users';
  static const String _entriesKey = 'local_entries';
  static const String _bugReportsKey = 'local_bug_reports';
  static const String _activityLogsKey = 'local_activity_logs';

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding $key: $e');
      return [];
    }
  }

  Future<void> _setList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  // ── User Operations ──────────────────────────────────────────────────

  Future<void> saveUser(AppUser user) async {
    final list = await _getList(_usersKey);
    final idx = list.indexWhere((m) => m['uid'] == user.uid);
    if (idx >= 0) {
      list[idx] = user.toMap();
    } else {
      list.add(user.toMap());
    }
    await _setList(_usersKey, list);
  }

  Future<AppUser?> getUser(String uid) async {
    final list = await _getList(_usersKey);
    final match = list.where((m) => m['uid'] == uid);
    if (match.isNotEmpty) {
      return AppUser.fromMap(match.first);
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final list = await _getList(_usersKey);
    return list.map((m) => AppUser.fromMap(m)).toList();
  }

  // ── Entry Operations ─────────────────────────────────────────────────

  Future<void> saveEntry(EntryRecord entry) async {
    final list = await _getList(_entriesKey);
    final idx = list.indexWhere((m) => m['id'] == entry.id);
    if (idx >= 0) {
      list[idx] = entry.toMap();
    } else {
      list.add(entry.toMap());
    }
    await _setList(_entriesKey, list);
  }

  Future<List<EntryRecord>> getUnsyncedEntries() async {
    final list = await _getList(_entriesKey);
    return list
        .where((m) => m['synced'] == 0 || m['synced'] == false)
        .map((m) => EntryRecord.fromMap(m))
        .toList();
  }

  Future<List<EntryRecord>> getAllEntries() async {
    final list = await _getList(_entriesKey);
    final entries = list.map((m) => EntryRecord.fromMap(m)).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> markEntriesSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final list = await _getList(_entriesKey);
    for (int i = 0; i < list.length; i++) {
      if (ids.contains(list[i]['id'])) {
        list[i]['synced'] = 1;
      }
    }
    await _setList(_entriesKey, list);
  }

  Future<void> upsertRemoteEntry(EntryRecord remoteRecord) async {
    final list = await _getList(_entriesKey);
    final idx = list.indexWhere((m) => m['id'] == remoteRecord.id);

    if (idx >= 0) {
      final localRecord = EntryRecord.fromMap(list[idx]);
      // Conflict resolution: last-write-wins
      if (remoteRecord.updatedAt.isAfter(localRecord.updatedAt)) {
        list[idx] = remoteRecord.copyWith(synced: true).toMap();
      }
    } else {
      list.add(remoteRecord.copyWith(synced: true).toMap());
    }
    await _setList(_entriesKey, list);
  }

  // ── Bug Report Operations ────────────────────────────────────────────

  Future<void> saveBugReport(BugReport report) async {
    final list = await _getList(_bugReportsKey);
    final idx = list.indexWhere((m) => m['id'] == report.id);
    if (idx >= 0) {
      list[idx] = report.toMap();
    } else {
      list.add(report.toMap());
    }
    await _setList(_bugReportsKey, list);
  }

  Future<List<BugReport>> getUnsyncedBugReports() async {
    final list = await _getList(_bugReportsKey);
    return list
        .where((m) => m['synced'] == 0 || m['synced'] == false)
        .map((m) => BugReport.fromMap(m))
        .toList();
  }

  Future<List<BugReport>> getAllBugReports() async {
    final list = await _getList(_bugReportsKey);
    final reports = list.map((m) => BugReport.fromMap(m)).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<void> markBugReportsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final list = await _getList(_bugReportsKey);
    for (int i = 0; i < list.length; i++) {
      if (ids.contains(list[i]['id'])) {
        list[i]['synced'] = 1;
      }
    }
    await _setList(_bugReportsKey, list);
  }

  Future<void> updateBugReportStatus(String id, String status) async {
    final list = await _getList(_bugReportsKey);
    for (int i = 0; i < list.length; i++) {
      if (list[i]['id'] == id) {
        list[i]['status'] = status;
        list[i]['updatedAt'] = DateTime.now().toIso8601String();
        list[i]['synced'] = 0;
        break;
      }
    }
    await _setList(_bugReportsKey, list);
  }

  // ── Activity Log Operations ──────────────────────────────────────────

  Future<void> saveActivityLog(ActivityLog log) async {
    final list = await _getList(_activityLogsKey);
    list.add(log.toMap());
    await _setList(_activityLogsKey, list);
  }

  Future<List<ActivityLog>> getUnsyncedActivityLogs() async {
    final list = await _getList(_activityLogsKey);
    return list
        .where((m) => m['synced'] == 0 || m['synced'] == false)
        .map((m) => ActivityLog.fromMap(m))
        .toList();
  }

  Future<void> markActivityLogsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final list = await _getList(_activityLogsKey);
    for (int i = 0; i < list.length; i++) {
      if (ids.contains(list[i]['id'])) {
        list[i]['synced'] = 1;
      }
    }
    await _setList(_activityLogsKey, list);
  }

  Future<int> getTotalEntryCount() async {
    final list = await _getList(_entriesKey);
    return list.length;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
    await prefs.remove(_bugReportsKey);
    await prefs.remove(_activityLogsKey);
    // Note: We don't remove _usersKey so past logins are remembered
  }
}
