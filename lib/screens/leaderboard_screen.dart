import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/expense_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _service = ExpenseService();

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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final monthTotal = _service.monthTotal;
    const avgMonthly = 44000;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final paceTotal = ((avgMonthly / daysInMonth) * dayOfMonth).round();

    final youRatio = monthTotal > 0
        ? (monthTotal / paceTotal).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildTopBar()),

          // ── Title ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Text(
                'You vs. average',
                style: GoogleFonts.rubik(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A1F14),
                ),
              ),
            ),
          ),

          // ── Comparison card ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E4),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBarRow(
                      label: 'You',
                      value: youRatio.toDouble(),
                      barColor: const Color(0xFFA8CCAC),
                      knobColor: const Color(0xFF2B4424),
                      knobChild: Text(
                        monthTotal > paceTotal * 0.5 ? '🤨' : '😊',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressBarRow(
                      label: 'Avg',
                      value: 0.5,
                      barColor: const Color(0xFFD2C7B5),
                      knobColor: const Color(0xFF7A7063),
                      knobChild: const Text(
                        '😎',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      monthTotal > 0
                          ? 'You\'ve spent ₹${_formatAmount(monthTotal)} of a ₹${_formatAmount(paceTotal)} pace so far this month'
                          : 'Start adding expenses to see your pace this month',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: const Color(0xFF9C8878),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Last 4 months ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST 4 MONTHS',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9C8878),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMonthlyChart(monthTotal),
                ],
              ),
            ),
          ),

          // ── Rank among friends ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RANK AMONG FRIENDS',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9C8878),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildRankCard(monthTotal),
                ],
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

  // ── Monthly chart ───────────────────────────────────────────────────────
  Widget _buildMonthlyChart(int currentMonthTotal) {
    final now = DateTime.now();
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final colors = [
      const Color(0xFFA8CCAC),
      const Color(0xFF9BAFD6),
      const Color(0xFFA8CCAC),
      const Color(0xFFD4826A),
    ];

    // Real data for all 4 months (past 3 + current)
    final months = <_MonthData>[];
    for (int i = 3; i >= 0; i--) {
      final targetMonth = now.month - i;
      final year = targetMonth <= 0 ? now.year - 1 : now.year;
      final month = targetMonth <= 0 ? targetMonth + 12 : targetMonth;
      final total = _service.monthlyTotalFor(year, month);
      months.add(_MonthData(
        name: monthNames[month - 1],
        amount: total,
      ));
    }

    final maxAmount = months
        .map((m) => m.amount)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(months.length, (index) {
            final month = months[index];
            final heightRatio = month.amount / maxAmount;
            final barHeight = month.amount > 0
                ? 24.0 + 95.0 * heightRatio
                : 6.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (month.amount > 0)
                      Text(
                        '₹${_formatAmount(month.amount)}',
                        style: GoogleFonts.rubik(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5C4A35),
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: month.amount > 0
                            ? colors[index]
                            : const Color(0xFFE8DCCB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      month.name,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C6A55),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Rank card ───────────────────────────────────────────────────────────
  Widget _buildRankCard(int monthTotal) {
    // Determine rank based on spending (lower = better rank)
    int rank;
    String description;
    if (monthTotal == 0) {
      rank = 1;
      description = '1st lowest spender';
    } else if (monthTotal < 10000) {
      rank = 1;
      description = '1st lowest spender';
    } else if (monthTotal < 20000) {
      rank = 2;
      description = '2nd lowest spender';
    } else if (monthTotal < 35000) {
      rank = 3;
      description = '3rd lowest spender';
    } else {
      rank = 5;
      description = '5th lowest spender';
    }

    return Container(
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
              color: const Color(0xFF8CB88A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.rubik(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A1F14),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Out of 6 friends this month',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  color: const Color(0xFF9C8878),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _MonthData {
  final String name;
  final int amount;
  const _MonthData({required this.name, required this.amount});
}
