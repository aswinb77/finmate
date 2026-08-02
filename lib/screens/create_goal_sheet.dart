import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import 'goal_journey_screen.dart';

class CreateGoalSheet extends StatefulWidget {
  const CreateGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5EFE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreateGoalSheet(),
    );
  }

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _goalService = GoalService();

  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _dateController = TextEditingController();
  final _initialController = TextEditingController();

  String _selectedEmoji = '🏝️';
  final _emojiOptions = ['🏝️', '📱', '💻', '🚗', '🏠', '✈️', '🎓', '🎸', '💰', '🎯'];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _dateController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    final targetStr = _targetController.text.trim();
    if (name.isEmpty || targetStr.isEmpty) return;

    final targetAmount = int.tryParse(targetStr);
    if (targetAmount == null || targetAmount <= 0) return;

    final date = _dateController.text.trim().isEmpty
        ? 'October'
        : _dateController.text.trim();
    final initial = int.tryParse(_initialController.text.trim()) ?? 0;

    _goalService.createGoal(
      name: name,
      targetAmount: targetAmount,
      targetDate: date,
      emoji: _selectedEmoji,
      initialSaved: initial,
    );

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalJourneyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentMilestones = Goal.generateMilestones(_nameController.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C4A8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Text(
                  'Create a Savings Goal',
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A1F14),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🎯', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 16),

            // Emoji Selection
            Text(
              'Pick an Icon',
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C6A55),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiOptions.length,
                itemBuilder: (context, index) {
                  final emoji = _emojiOptions[index];
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2A1F14)
                            : const Color(0xFFF7F1E4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2A1F14)
                              : const Color(0xFFE8DCCB),
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Goal Name Input
            _buildInputField(
              controller: _nameController,
              label: 'Goal Name',
              hint: 'e.g. Goa Trip, New iPhone',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Target Amount & Target Date Inputs
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _targetController,
                    label: 'Target Amount (₹)',
                    hint: 'e.g. 15000',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _dateController,
                    label: 'Target Month',
                    hint: 'e.g. October',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Initial Savings Input
            _buildInputField(
              controller: _initialController,
              label: 'Already Saved (₹)',
              hint: 'e.g. 0 or 2000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),

            // Milestone Preview
            Text(
              'AUTO-GENERATED MILESTONES',
              style: GoogleFonts.rubik(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9C8878),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: currentMilestones.map((ms) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(ms.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          '${(ms.percentage * 100).round()}%',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C4A35),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ms.label,
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              color: const Color(0xFF2A1F14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _handleCreate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'Create Goal 🚀',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C6A55),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1E4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DCCB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: const Color(0xFF2A1F14),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.rubik(
                fontSize: 13,
                color: const Color(0xFFB8A898),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
