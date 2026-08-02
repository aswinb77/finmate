import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate/services/goal_service.dart';
import 'package:finmate/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService().clearAllData();
  });

  test('loadLocalGoal leaves no active goal when no goal exists', () async {
    final goalService = GoalService();

    await goalService.loadLocalGoal(forceReload: true);

    expect(goalService.activeGoal, isNull);
  });
}
