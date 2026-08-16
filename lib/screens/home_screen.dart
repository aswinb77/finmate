import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/goal_service.dart';
import '../main.dart';
import 'vibes_screen.dart';
import 'goal_journey_screen.dart';
import 'create_goal_sheet.dart';
import '../widgets/auth_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ExpenseService();
  late String _currentFact;

  final _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    _currentFact = _service.getRandomFunFact(_service.todayTotal);
    _service.addListener(_onDataChanged);
    _goalService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    _goalService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      final total = _service.todayTotal;
      if (total > 0 && _currentFact.contains('Add expenses')) {
        _currentFact = _service.getRandomFunFact(total);
      }
      setState(() {});
    }
  }

  void _shuffleFact() {
    setState(() {
      _currentFact = _service.getRandomFunFact(_service.todayTotal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayExpenses = _service.todayExpenses;
    final todayTotal = _service.todayTotal;
    final unrated = _service.latestUnratedExpense;
    // Group today's expenses by category for Today's Story graph
    final categoryMap = <String, Expense>{};
    for (final e in todayExpenses) {
      if (categoryMap.containsKey(e.category)) {
        final existing = categoryMap[e.category]!;
        categoryMap[e.category] = Expense(
          id: existing.id,
          name: existing.category,
          amount: existing.amount + e.amount,
          category: existing.category,
          emoji: existing.emoji,
          color: existing.color,
          timestamp: existing.timestamp,
        );
      } else {
        categoryMap[e.category] = Expense(
          id: e.id,
          name: e.category,
          amount: e.amount,
          category: e.category,
          emoji: e.emoji,
          color: e.color,
          timestamp: e.timestamp,
        );
      }
    }
    final categoryStoryExpenses = categoryMap.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar()),
          SliverToBoxAdapter(child: _buildGreeting()),
          SliverToBoxAdapter(child: _buildSpendingHero(todayTotal)),
          SliverToBoxAdapter(child: _buildTodaysStory(categoryStoryExpenses)),
          if (unrated != null)
            SliverToBoxAdapter(child: _buildWorthIt(unrated)),
          SliverToBoxAdapter(child: _buildYouVsAverage()),
          SliverToBoxAdapter(child: _buildYourGoal()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
          GestureDetector(
            onTap: () => AuthModal.show(context),
            child: Container(
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
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: Color(0xFF2A1F14), size: 28),
            onPressed: () => AuthModal.show(context),
          ),
        ],
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Text(
        'Hey there 👋',
        style: GoogleFonts.rubik(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9C8878),
        ),
      ),
    );
  }

  // ── Spending hero ───────────────────────────────────────────────────────
  Widget _buildSpendingHero(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You've spent",
            style: GoogleFonts.rubik(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F14),
              height: 1.15,
            ),
          ),
          Text(
            '₹${_formatAmount(total)} today',
            style: GoogleFonts.rubik(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F14),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _shuffleFact,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: total > 0
                    ? const Color(0xFFE07B54)
                    : const Color(0xFF9C8878),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                _currentFact,
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TODAY'S STORY ───────────────────────────────────────────────────────
  Widget _buildTodaysStory(List<Expense> todayExpenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          child: Row(
            children: [
              Text(
                "TODAY'S STORY",
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9C8878),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (todayExpenses.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    context.findAncestorStateOfType<MainShellState>()
                        ?.switchTab(1);
                  },
                  child: Text(
                    'See all →',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C4A35),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (todayExpenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses yet today',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Head to Chat to add some! 💬',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: const Color(0xFF9C8878),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 12),
              itemCount: todayExpenses.length,
              itemBuilder: (context, index) {
                final expense = todayExpenses[index];
                final maxAmt = todayExpenses
                    .map((e) => e.amount)
                    .reduce((a, b) => a > b ? a : b);
                final ratio = (expense.amount / maxAmt).clamp(0.1, 1.0);
                return _StoryCircleItem(
                  expense: expense,
                  arcRatio: ratio,
                );
              },
            ),
          ),
      ],
    );
  }

  // ── YOUR GOAL ───────────────────────────────────────────────────────────
  Widget _buildYourGoal() {
    final goal = _goalService.activeGoal;

    if (goal == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "YOUR GOAL",
              style: GoogleFonts.rubik(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9C8878),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => CreateGoalSheet.show(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E4),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1F14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('🎯', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create a Goal',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A1F14),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Set a savings target & track your journey!',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              color: const Color(0xFF9C8878),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_rounded,
                      color: Color(0xFF2A1F14),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "YOUR GOAL",
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9C8878),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => CreateGoalSheet.show(context),
                child: Text(
                  '+ New ',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9C8878),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GoalJourneyScreen(),
                    ),
                  );
                },
                child: Text(
                  'See journey →',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C4A35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GoalJourneyScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE08E6D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        goal.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${goal.name} — ${goal.percentage}% there',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2A1F14),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_formatAmount(goal.currentAmount)} of ₹${_formatAmount(goal.targetAmount)} saved',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: const Color(0xFF9C8878),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WORTH IT? ───────────────────────────────────────────────────────────
  Widget _buildWorthIt(Expense expense) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "WORTH IT?",
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9C8878),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (_service.ratedCount > 0)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VibesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'More →',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C4A35),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${expense.emoji} ${expense.name} — ₹${expense.amount}',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A1F14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ExpenseService.formatTime(expense.timestamp),
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: const Color(0xFF9C8878),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _service.setMood(expense.id, i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE5D2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Text(Expense.moodEmojis[i],
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                Expense.moodLabels[i],
                                style: GoogleFonts.rubik(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7C6A55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // ── YOU VS. AVERAGE ─────────────────────────────────────────────────────
  Widget _buildYouVsAverage() {
    final monthTotal = _service.monthTotal;
    const avgMonthly = 30000;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final paceTotal = ((avgMonthly / daysInMonth) * dayOfMonth).round();

    // Ratios for progress bars
    final youRatio = monthTotal > 0
        ? (monthTotal / paceTotal).clamp(0.0, 1.0)
        : 0.0;
    const avgRatio = 0.58;

    // Calculate percentage difference vs pace
    final paceDiff = paceTotal - monthTotal;
    final diffPct = paceTotal > 0
        ? ((paceDiff / paceTotal) * 100).abs().round()
        : 16;
    final isBelow = monthTotal <= paceTotal;

    final pacingText = isBelow
        ? 'Pacing $diffPct% below average this month 🎉'
        : 'Pacing $diffPct% above average this month 😬';

    final pacingColor = isBelow
        ? const Color(0xFF2A5427)
        : const Color(0xFFB54C34);

    final youEmoji = isBelow ? '🙂' : '🤨';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "YOU VS. AVERAGE",
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9C8878),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.findAncestorStateOfType<MainShellState>()
                      ?.switchTab(3);
                },
                child: Text(
                  'Details →',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C4A35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // You Row
                _buildProgressBarRow(
                  label: 'You',
                  value: youRatio.toDouble(),
                  barColor: const Color(0xFFA8CCAC),
                  knobColor: const Color(0xFF2B4424),
                  knobChild: Text(
                    youEmoji,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // Avg Row
                _buildProgressBarRow(
                  label: 'Avg',
                  value: avgRatio,
                  barColor: const Color(0xFFD2C7B5),
                  knobColor: const Color(0xFF7A7063),
                  knobChild: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F1E4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pacing status text
                Text(
                  pacingText,
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pacingColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarRow({
    required String label,
    required double value,
    required Color barColor,
    required Color knobColor,
    required Widget knobChild,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D2C1E),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              const trackHeight = 12.0;
              const knobSize = 28.0;
              final clampedValue = value.clamp(0.0, 1.0);
              final fillWidth =
                  (maxWidth * clampedValue).clamp(knobSize / 2, maxWidth);
              final knobLeft =
                  (fillWidth - knobSize / 2).clamp(0.0, maxWidth - knobSize);

              return SizedBox(
                height: knobSize,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Track background
                    Container(
                      height: trackHeight,
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5D2),
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                      ),
                    ),
                    // Progress fill bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: trackHeight,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                      ),
                    ),
                    // Knob indicator
                    Positioned(
                      left: knobLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          color: knobColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: knobChild),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
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
}

// ── Story Circle Item ─────────────────────────────────────────────────────
class _StoryCircleItem extends StatelessWidget {
  final Expense expense;
  final double arcRatio; // 0.0–1.0, controls arc length

  const _StoryCircleItem({
    required this.expense,
    required this.arcRatio,
  });

  static const _iconMap = {
    'Food': Icons.restaurant_rounded,
    'Transit': Icons.directions_transit_filled_rounded,
    'Fun': Icons.movie_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Health': Icons.favorite_rounded,
    'Other': Icons.grid_view_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[expense.category] ?? Icons.grid_view_rounded;
    const circleSize = 76.0;

    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle with arc ring
          SizedBox(
            width: circleSize + 16,
            height: circleSize + 16,
            child: CustomPaint(
              painter: _ArcPainter(
                color: expense.color,
                sweepFraction: arcRatio,
              ),
              child: Center(
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: expense.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: expense.color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    iconData,
                    size: 30,
                    color: const Color(0xFF2A1F14).withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Amount
          Text(
            '₹${expense.amount}',
            style: GoogleFonts.rubik(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F14),
            ),
          ),
          const SizedBox(height: 2),
          // Name
          Text(
            expense.name,
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9C8878),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final Color color;
  final double sweepFraction; // 0.0–1.0

  const _ArcPainter({required this.color, required this.sweepFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 4;

    // Background track (faint full circle)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Foreground arc (sweeps clockwise from top-left, -140° to sweepFraction)
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const startAngle = -2.44; // ~-140° in radians (top-left)
    final sweepAngle = sweepFraction * 4.89; // max ~280° sweep

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.sweepFraction != sweepFraction;
}

