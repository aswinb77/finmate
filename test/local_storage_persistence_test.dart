import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate/models/activity_log.dart';
import 'package:finmate/models/bug_report.dart';
import 'package:finmate/models/entry_record.dart';
import 'package:finmate/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
    await storage.clearAllData();
  });

  test('migrates guest data to an authenticated user account', () async {
    final guestEntry = EntryRecord(
      id: 'entry-1',
      userId: 'guest_user',
      type: 'expense',
      payload: {'amount': 15},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );

    final guestBug = BugReport(
      id: 'bug-1',
      userId: 'guest_user',
      userEmail: 'guest@example.com',
      description: 'Description',
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );

    final guestLog = ActivityLog(
      id: 'log-1',
      userId: 'guest_user',
      action: 'add_expense',
      createdAt: DateTime.now(),
      synced: false,
    );

    await storage.saveEntry(guestEntry);
    await storage.saveBugReport(guestBug);
    await storage.saveActivityLog(guestLog);

    await storage.migrateUserData(fromUserId: 'guest_user', toUserId: 'user_123');

    final entries = await storage.getEntriesForUser('user_123');
    final bugs = await storage.getBugReportsForUser('user_123');
    final logs = await storage.getActivityLogsForUser('user_123');

    expect(entries, hasLength(1));
    expect(bugs, hasLength(1));
    expect(logs, hasLength(1));
    expect(entries.single.userId, 'user_123');
    expect(bugs.single.userId, 'user_123');
    expect(logs.single.userId, 'user_123');
  });
}
