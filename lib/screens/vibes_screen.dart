import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/category_icon.dart';

class VibesScreen extends StatefulWidget {
  const VibesScreen({super.key});

  @override
  State<VibesScreen> createState() => _VibesScreenState();
}

class _VibesScreenState extends State<VibesScreen> {
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
    final moodScores = _service.categoryMoodScores;
    final regrets = _service.weeklyRegrets;
    final loved = _service.weeklyLoved;
    final ratedCount = _service.ratedCount;

    // Compute overall regret score
    double overallScore = 0;
    if (moodScores.isNotEmpty) {
      overallScore = moodScores.values.reduce((a, b) => a + b) /
          moodScores.values.length;
    }
    final overallLabel = overallScore < 0.7
        ? 'Low'
        : overallScore < 1.3
            ? 'Medium'
            : 'High';
    final overallEmoji = overallScore < 0.7
        ? '🎉'
        : overallScore < 1.3
            ? '🤷'
            : '😬';

    // Sort categories
    final sortedCats = moodScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Back bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F1E4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded,
                              color: Color(0xFF2A1F14), size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Text(
                  'Spend vibes',
                  style: GoogleFonts.rubik(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A1F14),
                  ),
                ),
              ),
            ),

            // ── Regret score card ─────────────────────────────────────
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
                      Text(
                        "This week's regret score",
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D2C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            overallLabel,
                            style: GoogleFonts.rubik(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2A1F14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(overallEmoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Based on $ratedCount mood taps this week',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: const Color(0xFF9C8878),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category pills
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: sortedCats.map((entry) {
                          final score = entry.value;
                          final color = score < 0.7
                              ? const Color(0xFFA8CCAC)
                              : score < 1.3
                                  ? const Color(0xFFE8C84A)
                                  : const Color(0xFFD4826A);
                          final label = score < 0.7
                              ? 'low regret'
                              : score < 1.3
                                  ? 'so-so'
                                  : 'high regret';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  entry.key,
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: color.withValues(alpha: 1.0),
                                  ),
                                ),
                                Text(
                                  label,
                                  style: GoogleFonts.rubik(
                                    fontSize: 11,
                                    color: const Color(0xFF7C6A55),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Biggest regret this week ──────────────────────────────
            if (regrets.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIGGEST REGRET THIS WEEK',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9C8878),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildRegretCards(regrets),
                    ],
                  ),
                ),
              ),

            // ── Most loved spend ──────────────────────────────────────
            if (loved.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOST LOVED SPEND',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9C8878),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildLovedCards(loved),
                    ],
                  ),
                ),
              ),

            // Empty state
            if (moodScores.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🎭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'No vibes yet',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D2C1E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rate your expenses in the Worth It? card\nto see your spending vibes here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: const Color(0xFF9C8878),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRegretCards(List<Expense> regrets) {
    // Group by name, show top regret with count
    final groups = <String, List<Expense>>{};
    for (final e in regrets) {
      groups.putIfAbsent(e.name.toLowerCase(), () => []).add(e);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) {
        final totalA = a.value.fold(0, (sum, e) => sum + e.amount);
        final totalB = b.value.fold(0, (sum, e) => sum + e.amount);
        return totalB.compareTo(totalA);
      });

    return sorted.take(3).map((entry) {
      final items = entry.value;
      final rep = items.first;
      final total = items.fold(0, (sum, e) => sum + e.amount);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD4826A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: CategoryIcon(
                  category: rep.category,
                  emoji: rep.emoji,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rep.name} — ${items.length} ${items.length == 1 ? "time" : "times"}',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                  Text(
                    '₹$total total · tagged 😩 all ${items.length} times',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: const Color(0xFF9C8878),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildLovedCards(List<Expense> loved) {
    final groups = <String, List<Expense>>{};
    for (final e in loved) {
      groups.putIfAbsent(e.name.toLowerCase(), () => []).add(e);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return sorted.take(3).map((entry) {
      final items = entry.value;
      final rep = items.first;
      final avg =
          (items.fold(0, (sum, e) => sum + e.amount) / items.length).round();

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8CB88A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: CategoryIcon(
                  category: rep.category,
                  emoji: rep.emoji,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rep.name,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                  Text(
                    '₹$avg avg · tagged 😍 ${items.length} ${items.length == 1 ? "time" : "times"}',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: const Color(0xFF9C8878),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
