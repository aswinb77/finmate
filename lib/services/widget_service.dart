import 'package:home_widget/home_widget.dart';
import '../services/expense_service.dart';

/// Writes live expense data into Android SharedPreferences so the
/// home-screen widget can read it via DragonWidgetProvider.
class WidgetService {
  static const String _mediumWidgetName = 'DragonWidgetProvider';
  static const String _smallWidgetName = 'DragonWidgetSmallProvider';

  /// Push the latest data from [ExpenseService] to the widget.
  static Future<void> updateWidget(ExpenseService svc) async {
    try {
      final todaySpent      = svc.todayTotal;
      final transactions    = svc.todayExpenses.length;
      final dailyLimit      = 2000; // TODO: wire from user prefs if you add limits
      final leftToSpend     = (dailyLimit - todaySpent).clamp(0, dailyLimit);
      final weekTotal       = _weekTotal(svc);

      await HomeWidget.saveWidgetData<int>('spent',        todaySpent);
      await HomeWidget.saveWidgetData<int>('transactions', transactions);
      await HomeWidget.saveWidgetData<int>('limit',        dailyLimit);
      await HomeWidget.saveWidgetData<int>('leftToSpend',  leftToSpend);
      await HomeWidget.saveWidgetData<int>('weekTotal',    weekTotal);

      await HomeWidget.updateWidget(
        androidName: _mediumWidgetName,
      );
      await HomeWidget.updateWidget(
        androidName: _smallWidgetName,
      );
    } catch (_) {
      // Widget not placed on home screen — silently ignore.
    }
  }

  static int _weekTotal(ExpenseService svc) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return svc.expenses
        .where((e) => e.timestamp.isAfter(weekAgo))
        .fold(0, (sum, e) => sum + e.amount);
  }
}
