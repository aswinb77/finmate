import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _service = ExpenseService();
  int _selectedDayIndex = 0;
  bool _isMonthZoom = false; // Default to Month overview

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _weekdaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<_DayTab> _buildDayTabs() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find earliest expense date
    final allExpenses = _service.expenses;
    DateTime earliestDate = today;

    if (allExpenses.isNotEmpty) {
      for (final e in allExpenses) {
        final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
        if (d.isBefore(earliestDate)) {
          earliestDate = d;
        }
      }
    }

    final daysDifference = today.difference(earliestDate).inDays;
    final totalDays = (daysDifference + 1).clamp(1, 60);

    final tabs = <_DayTab>[];
    for (int i = 0; i < totalDays; i++) {
      final date = today.subtract(Duration(days: i));
      String label;
      if (i == 0) {
        label = 'Today';
      } else if (i == 1) {
        label = 'Yest';
      } else {
        label = dayNames[date.weekday - 1];
      }
      tabs.add(_DayTab(label: label, date: date));
    }
    return tabs;
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Drinks':
        return Icons.coffee_rounded;
      case 'Transit':
        return Icons.directions_bus_rounded;
      case 'Metro':
        return Icons.subway_rounded;
      case 'Fun':
        return Icons.movie_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static String? _timeGap(DateTime a, DateTime b) {
    final diff = b.difference(a);
    if (diff.inMinutes < 30) return null;
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m gap';
    if (hours > 0) return '${hours}h gap';
    return '${mins}m gap';
  }

  /// Algorithmic Decision Tree for Auto-Generated One-Line Captions
  String _generateDayCaption(List<Expense> dayExpenses, double userDailyAverage) {
    if (dayExpenses.isEmpty) {
      return 'Quiet weekday';
    }

    final dayTotal = dayExpenses.fold(0, (sum, e) => sum + e.amount);
    final names = dayExpenses.map((e) => e.name.toLowerCase()).toList();

    final hasMovie = names.any((n) => n.contains('movie') || n.contains('pvr') || n.contains('ticket'));
    final hasSwiggy = names.any((n) => n.contains('swiggy') || n.contains('zomato') || n.contains('dinner'));
    final hasGrocery = names.any((n) => n.contains('grocery') || n.contains('thali') || n.contains('lunch'));

    if (hasMovie && hasSwiggy) return 'Movie + Swiggy dinner';
    if (hasMovie) return 'Movie night';
    if (hasSwiggy) return 'Late-night Swiggy';
    if (hasGrocery) return 'Grocery run';

    // Stand-out single item
    final biggest = dayExpenses.reduce((a, b) => a.amount > b.amount ? a : b);
    if (biggest.amount >= 500) {
      return biggest.name;
    }

    if (dayTotal < 350) return 'Light day';
    if (dayTotal < 500) return 'Quiet weekday';
    if (dayTotal < 800) return 'Steady day';
    if (dayTotal >= 1000) return 'Payday treats';

    return 'Regular day';
  }

  String _formatMonthNodeTitle(int index, DateTime date) {
    final weekdayStr = _weekdaysShort[date.weekday - 1];
    final monthStr = _monthsShort[date.month - 1];
    if (index == 0) {
      return 'Today · $weekdayStr ${date.day} $monthStr';
    }
    return '$weekdayStr ${date.day} $monthStr';
  }

  static String _formatAmount(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return str;
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result.write(str[i]);
      count++;
      if (i > 0) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          result.write(',');
        }
      }
    }
    return result.toString().split('').reversed.join();
  }

  static String _formatCompact(int amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.roundToDouble()
          ? '${k.round()},${(amount % 1000).toString().padLeft(3, '0').substring(0, 3)}'
          : amount.toString();
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentTabs = _buildDayTabs();
    final safeIndex = _selectedDayIndex.clamp(0, currentTabs.length - 1);
    final selectedDate = currentTabs[safeIndex].date;
    final dayExpenses = _service.expensesForDate(selectedDate);
    final userDailyAverage = (_service.monthTotal / 30).clamp(300.0, 5000.0);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildTopBar()),

          // ── Title & Zoom Switcher ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Your story',
                    style: GoogleFonts.rubik(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                  const Spacer(),
                  _buildZoomTogglePill(),
                ],
              ),
            ),
          ),

          // ── Day Filter Circles (shown in Day Details view) ────────────
          if (!_isMonthZoom)
            SliverToBoxAdapter(child: _buildDayCircles(currentTabs)),

          // ── Main Story Thread View Card ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: _isMonthZoom
                  ? _buildMonthThreadView(currentTabs, userDailyAverage)
                  : (dayExpenses.isEmpty
                      ? _buildEmptyState()
                      : _buildDayThreadView(currentTabs, dayExpenses)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zoom Toggle Control ───────────────────────────────────────────────────
  Widget _buildZoomTogglePill() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isMonthZoom = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !_isMonthZoom ? const Color(0xFF2A1F14) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Day',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !_isMonthZoom ? Colors.white : const Color(0xFF7C6A55),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isMonthZoom = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isMonthZoom ? const Color(0xFF2A1F14) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Month',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isMonthZoom ? Colors.white : const Color(0xFF7C6A55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Level 1: Month / Days Overview Thread ────────────────────────────────
  Widget _buildMonthThreadView(List<_DayTab> currentTabs, double userDailyAverage) {
    final thisWeekTabs = currentTabs.take(7).toList();
    final lastWeekTabs = currentTabs.skip(7).toList();

    final badgeColors = const [
      Color(0xFFE08E6D), // coral
      Color(0xFFE8C84A), // gold/yellow
      Color(0xFF9BAFD6), // soft blue
      Color(0xFFA8CCAC), // soft green
      Color(0xFFE89CAE), // soft pink
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle help text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Text(
              'Dates, not just weekdays — so two Mondays never get mixed up. Tap a day to zoom in.',
              style: GoogleFonts.rubik(
                fontSize: 13,
                color: const Color(0xFF9C8878),
                height: 1.4,
              ),
            ),
          ),

          // THIS WEEK Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Text(
              'THIS WEEK',
              style: GoogleFonts.rubik(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9C8878),
                letterSpacing: 1.2,
              ),
            ),
          ),

          // THIS WEEK Nodes
          ...List.generate(thisWeekTabs.length, (i) {
            final isFirst = i == 0;
            final isLast = i == thisWeekTabs.length - 1 && lastWeekTabs.isEmpty;
            final tab = thisWeekTabs[i];
            final dayExpenses = _service.expensesForDate(tab.date);
            final dayTotal = dayExpenses.fold(0, (sum, e) => sum + e.amount);
            final caption = _generateDayCaption(dayExpenses, userDailyAverage);
            final badgeColor = badgeColors[i % badgeColors.length];

            return _buildMonthNodeItem(
              index: i,
              tab: tab,
              dayTotal: dayTotal,
              caption: caption,
              badgeColor: badgeColor,
              isFirst: isFirst,
              isLast: isLast,
            );
          }),

          // LAST WEEK Header
          if (lastWeekTabs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'LAST WEEK',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9C8878),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...List.generate(lastWeekTabs.length, (i) {
              final globalIndex = i + 7;
              final isLast = i == lastWeekTabs.length - 1;
              final tab = lastWeekTabs[i];
              final dayExpenses = _service.expensesForDate(tab.date);
              final dayTotal = dayExpenses.fold(0, (sum, e) => sum + e.amount);
              final caption = _generateDayCaption(dayExpenses, userDailyAverage);
              final badgeColor = badgeColors[globalIndex % badgeColors.length];

              return _buildMonthNodeItem(
                index: globalIndex,
                tab: tab,
                dayTotal: dayTotal,
                caption: caption,
                badgeColor: badgeColor,
                isFirst: false,
                isLast: isLast,
              );
            }),
          ],

          // Inline End of Month Notice matching mockup!
          _buildBottomInlineNotice(),
        ],
      ),
    );
  }

  Widget _buildMonthNodeItem({
    required int index,
    required _DayTab tab,
    required int dayTotal,
    required String caption,
    required Color badgeColor,
    required bool isFirst,
    required bool isLast,
  }) {
    final title = _formatMonthNodeTitle(index, tab.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: isFirst
                          ? null
                          : const _DashedLinePainter(color: Color(0xFFD4C4A8)),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${tab.date.day}',
                          style: GoogleFonts.rubik(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _weekdaysShort[tab.date.weekday - 1].toUpperCase(),
                          style: GoogleFonts.rubik(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: isLast
                          ? null
                          : const _DashedLinePainter(color: Color(0xFFD4C4A8)),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                    _isMonthZoom = false; // Zoom into day details!
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.rubik(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2A1F14),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              caption,
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: const Color(0xFF9C8878),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dayTotal > 0 ? '₹${_formatAmount(dayTotal)}' : '—',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2A1F14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Level 2: Day / Transactions Detailed Thread ──────────────────────────
  Widget _buildDayThreadView(List<_DayTab> currentTabs, List<Expense> rawExpenses) {
    final expenses = List<Expense>.from(rawExpenses)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final total = expenses.fold(0, (sum, e) => sum + e.amount);

  final items = <Widget>[];
  for (int i = 0; i < expenses.length; i++) {
    final isFirst = i == 0;
    final isLast = i == expenses.length - 1;
    items.add(_buildTimelineEntry(expenses[i], isFirst, isLast));

    if (!isLast) {
      final gap = _timeGap(expenses[i + 1].timestamp, expenses[i].timestamp);
      if (gap != null) {
        items.add(_buildGapBadge(gap));
      }
    }
  }

    final safeIndex = _selectedDayIndex.clamp(0, currentTabs.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMonthZoom = true),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          size: 16, color: Color(0xFF9C8878)),
                      const SizedBox(width: 4),
                      Text(
                        '${currentTabs[safeIndex].label} · ${expenses.length} expenses',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9C8878),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ₹$total',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2C1E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: Color(0xFFE8DCCB),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          ...items,
          _buildBottomInlineNotice(),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(Expense expense, bool isFirst, bool isLast) {
    final icon = _categoryIcon(expense.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: isFirst
                          ? null
                          : const _DashedLinePainter(color: Color(0xFFD4C4A8)),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: expense.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(icon,
                          size: 22,
                          color: const Color(0xFF2A1F14).withValues(alpha: 0.65)),
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: isLast
                          ? null
                          : const _DashedLinePainter(color: Color(0xFFD4C4A8)),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            expense.name,
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A1F14),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ExpenseService.formatTime(expense.timestamp)} · ${expense.category}',
                            style: GoogleFonts.rubik(
                              fontSize: 12,
                              color: const Color(0xFF9C8878),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${expense.amount}',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A1F14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGapBadge(String gap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Center(
              child: CustomPaint(
                painter: const _DashedLinePainter(color: Color(0xFFD4C4A8)),
                child: const SizedBox(width: 2, height: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE5D2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8DCCB),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  gap,
                  style: GoogleFonts.rubik(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7C6A55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── "That's it for the month 🎉" Inline Notice
  Widget _buildBottomInlineNotice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 24),
      child: Row(
        children: [
          Image.asset(
            'assets/wizard_duck.png',
            height: 32,
            width: 32,
            color: const Color(0xFFF7F1E4),
            colorBlendMode: BlendMode.multiply,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text('🐤', style: TextStyle(fontSize: 20));
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'That\'s it for the month 🎉',
              style: GoogleFonts.rubik(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C6A55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('◆',
                  style: TextStyle(fontSize: 20, color: Color(0xFFE8C84A))),
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              const Icon(Icons.notifications_rounded,
                  color: Color(0xFFD4A853), size: 30),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B54),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFF5EFE0), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Day filter circles ──────────────────────────────────────────────────
  Widget _buildDayCircles(List<_DayTab> currentTabs) {
    final topFiveTabs = currentTabs.take(5).toList();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: topFiveTabs.length,
        itemBuilder: (context, index) {
          final isActive = _selectedDayIndex == index;
          final tab = topFiveTabs[index];
          final dayTotal = _service.expensesForDate(tab.date)
              .fold(0, (sum, e) => sum + e.amount);

          final ringColor = isActive
              ? const Color(0xFFD4826A)
              : const Color(0xFFD4C4A8);

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ringColor,
                        width: isActive ? 2.5 : 1.5,
                      ),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        tab.label,
                        style: GoogleFonts.rubik(
                          fontSize: isActive ? 13 : 12,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF2A1F14)
                              : const Color(0xFF7C6A55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayTotal > 0 ? '₹${_formatCompact(dayTotal)}' : '—',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF2A1F14)
                          : const Color(0xFF9C8878),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text('📖', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            'No expenses this day',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D2C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Head to Chat to start tracking! 💬',
            style: GoogleFonts.rubik(
              fontSize: 13,
              color: const Color(0xFF9C8878),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashGap = 4.0;
    double startY = 0;
    final x = size.width / 2;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayTab {
  final String label;
  final DateTime date;
  const _DayTab({required this.label, required this.date});
}
