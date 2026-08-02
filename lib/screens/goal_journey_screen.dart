import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import 'create_goal_sheet.dart';

class GoalJourneyScreen extends StatefulWidget {
  const GoalJourneyScreen({super.key});

  @override
  State<GoalJourneyScreen> createState() => _GoalJourneyScreenState();
}

class _GoalJourneyScreenState extends State<GoalJourneyScreen> {
  final _goalService = GoalService();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _goalService.removeListener(_onDataChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _handleAdd() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final amount = int.tryParse(text);
    if (amount != null && amount != 0) {
      _goalService.addAmount(amount);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
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

  @override
  Widget build(BuildContext context) {
    final goal = _goalService.activeGoal;
    if (goal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5EFE0),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No goal set yet',
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A1F14),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => CreateGoalSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1F14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Create a Goal',
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final progress = goal.progressRatio;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Back bar ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.reply_rounded,
                                  color: Color(0xFF2A1F14),
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal.name,
                                  style: GoogleFonts.rubik(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2A1F14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => CreateGoalSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F1E4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE8DCCB)),
                              ),
                              child: Text(
                                '+ New Goal',
                                style: GoogleFonts.rubik(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5C4A35),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Header Card ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F1E4),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${_formatAmount(goal.currentAmount)}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2A1F14),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'of ₹${_formatAmount(goal.targetAmount)}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF9C8878),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${goal.percentage}% there · ₹${_formatAmount(goal.remainingAmount)} to go · on track for ${goal.targetDate} 🎉',
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

                  // ── Section Title ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'YOUR JOURNEY',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9C8878),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // ── Journey Path Card ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F1E4),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: _buildJourneyTimeline(goal, progress),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Action Input Bar ─────────────────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyTimeline(Goal goal, double progress) {
    // Reverse milestones to render 100% at top, 0% at bottom
    final milestones = goal.milestones.reversed.toList();

    // Check where "You are here" marker belongs
    final currentAmount = goal.currentAmount;

    final items = <Widget>[];

    for (int i = 0; i < milestones.length; i++) {
      final ms = milestones[i];
      final target = ms.targetAmountFor(goal.targetAmount);
      final isUnlocked = currentAmount >= target;

      // Check if we should insert "You are here" BEFORE this milestone (since list is top-down)
      final nextMs = (i < milestones.length - 1) ? milestones[i + 1] : null;
      final nextTarget = nextMs?.targetAmountFor(goal.targetAmount) ?? 0;

      final isCurrentHere = (currentAmount < target) && (currentAmount >= nextTarget);
      final isExactMatch = currentAmount == target;

      items.add(_buildMilestoneRow(
        label: ms.label,
        amount: target,
        emoji: ms.emoji,
        isUnlocked: isUnlocked,
        isTop: i == 0,
        isBottom: i == milestones.length - 1,
        progress: progress,
        msProgress: ms.percentage,
      ));

      // Insert "You are here" marker if current position falls between milestones
      if (isCurrentHere && !isExactMatch) {
        items.add(_buildYouAreHereRow(currentAmount, progress));
      }
    }

    return Column(
      children: items,
    );
  }

  Widget _buildMilestoneRow({
    required String label,
    required int amount,
    required String emoji,
    required bool isUnlocked,
    required bool isTop,
    required bool isBottom,
    required double progress,
    required double msProgress,
  }) {
    // Line color logic
    final isLineFilled = progress >= msProgress;
    final lineLineColor = isLineFilled
        ? const Color(0xFFA8CCAC)
        : const Color(0xFFE8DCCB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline node column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: isTop ? Colors.transparent : lineLineColor,
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFFA8CCAC).withValues(alpha: 0.4)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? const Color(0xFF2B5427)
                          : const Color(0xFFD4C4A8),
                      width: isUnlocked ? 2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: isBottom ? Colors.transparent : lineLineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Milestone Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatAmount(amount)}',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: const Color(0xFF9C8878),
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

  Widget _buildYouAreHereRow(int currentAmount, double progress) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline node column for "You are here"
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: const Color(0xFFA8CCAC),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4826A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8B4231),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4826A).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🙂', style: TextStyle(fontSize: 20)),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: const Color(0xFFA8CCAC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You are here',
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5C261A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatAmount(currentAmount)}',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9C8878),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE8DCCB),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  color: const Color(0xFF2A1F14),
                ),
                decoration: InputDecoration(
                  hintText: 'Add to this goal, e.g. 500',
                  hintStyle: GoogleFonts.rubik(
                    fontSize: 14,
                    color: const Color(0xFFB8A898),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _handleAdd(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Add ₹',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
