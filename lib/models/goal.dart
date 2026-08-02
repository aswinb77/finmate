class GoalMilestone {
  final double percentage; // 0.0 to 1.0
  final String label;
  final String emoji;

  const GoalMilestone({
    required this.percentage,
    required this.label,
    required this.emoji,
  });

  int targetAmountFor(int totalTarget) => (totalTarget * percentage).round();

  Map<String, dynamic> toMap() {
    return {
      'percentage': percentage,
      'label': label,
      'emoji': emoji,
    };
  }

  factory GoalMilestone.fromMap(Map<String, dynamic> map) {
    return GoalMilestone(
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🌱',
    );
  }
}

class Goal {
  final String id;
  final String name;
  final String emoji;
  final int targetAmount;
  int currentAmount;
  final String targetDate;
  final List<GoalMilestone> milestones;

  Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.milestones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate,
      'milestones': milestones.map((m) => m.toMap()).toList(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    List<GoalMilestone> msList = [];
    if (map['milestones'] is List) {
      msList = (map['milestones'] as List)
          .map((m) => GoalMilestone.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    }
    return Goal(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Goal',
      emoji: map['emoji'] as String? ?? '🎯',
      targetAmount: (map['targetAmount'] as num?)?.toInt() ?? 0,
      currentAmount: (map['currentAmount'] as num?)?.toInt() ?? 0,
      targetDate: map['targetDate'] as String? ?? 'Upcoming',
      milestones: msList,
    );
  }

  int get percentage => targetAmount > 0
      ? ((currentAmount / targetAmount) * 100).round().clamp(0, 100)
      : 0;

  double get progressRatio => targetAmount > 0
      ? (currentAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;

  int get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, targetAmount);

  static List<GoalMilestone> generateMilestones(String goalName) {
    final cleanTitle = goalName.trim().isEmpty ? 'Goal' : goalName.trim();
    final lower = cleanTitle.toLowerCase();

    // 1. Travel / Trip / Vacation / Trek
    if (lower.contains('trip') ||
        lower.contains('goa') ||
        lower.contains('travel') ||
        lower.contains('vacation') ||
        lower.contains('flight') ||
        lower.contains('trek') ||
        lower.contains('hike') ||
        lower.contains('beach') ||
        lower.contains('tour') ||
        lower.contains('holiday')) {
      return [
        GoalMilestone(percentage: 0.0, label: 'Start saving for $cleanTitle', emoji: '🎒'),
        const GoalMilestone(percentage: 0.25, label: 'Booked transport', emoji: '🚌'),
        const GoalMilestone(percentage: 0.50, label: 'Stay sorted', emoji: '🏨'),
        const GoalMilestone(percentage: 0.75, label: 'Spending money set', emoji: '🍹'),
        GoalMilestone(percentage: 1.0, label: '$cleanTitle unlocked!', emoji: '🎉'),
      ];
    }

    // 2. Electronics / Tech / Gadgets
    if (lower.contains('phone') ||
        lower.contains('iphone') ||
        lower.contains('laptop') ||
        lower.contains('mac') ||
        lower.contains('gadget') ||
        lower.contains('ps5') ||
        lower.contains('camera') ||
        lower.contains('watch') ||
        lower.contains('pc') ||
        lower.contains('tv')) {
      return [
        GoalMilestone(percentage: 0.0, label: 'Eye on $cleanTitle', emoji: '📱'),
        const GoalMilestone(percentage: 0.25, label: 'Down payment ready', emoji: '💳'),
        GoalMilestone(percentage: 0.50, label: 'Halfway to $cleanTitle', emoji: '💻'),
        const GoalMilestone(percentage: 0.75, label: 'Cart fully loaded', emoji: '🛍️'),
        const GoalMilestone(percentage: 1.0, label: 'Unboxed & ready!', emoji: '🥳'),
      ];
    }

    // 3. Vehicle / Car / Bike
    if (lower.contains('car') ||
        lower.contains('bike') ||
        lower.contains('vehicle') ||
        lower.contains('scooter') ||
        lower.contains('ev') ||
        lower.contains('ride')) {
      return [
        GoalMilestone(percentage: 0.0, label: 'First deposit for $cleanTitle', emoji: '🔑'),
        const GoalMilestone(percentage: 0.25, label: 'Test ride complete', emoji: '🏍️'),
        const GoalMilestone(percentage: 0.50, label: 'Down payment locked', emoji: '🚗'),
        const GoalMilestone(percentage: 0.75, label: 'Insurance covered', emoji: '📄'),
        GoalMilestone(percentage: 1.0, label: 'Keys to $cleanTitle in hand!', emoji: '🏎️'),
      ];
    }

    // 4. Education / Courses
    if (lower.contains('course') ||
        lower.contains('college') ||
        lower.contains('exam') ||
        lower.contains('degree') ||
        lower.contains('certif') ||
        lower.contains('book') ||
        lower.contains('school')) {
      return [
        const GoalMilestone(percentage: 0.0, label: 'Application filed', emoji: '📝'),
        const GoalMilestone(percentage: 0.25, label: 'Study materials bought', emoji: '📚'),
        GoalMilestone(percentage: 0.50, label: 'Halfway to $cleanTitle', emoji: '🎓'),
        const GoalMilestone(percentage: 0.75, label: 'Exam fee covered', emoji: '🏫'),
        const GoalMilestone(percentage: 1.0, label: 'Certified & complete!', emoji: '🎓'),
      ];
    }

    // 5. Home / Living / Furniture
    if (lower.contains('home') ||
        lower.contains('house') ||
        lower.contains('rent') ||
        lower.contains('flat') ||
        lower.contains('decor') ||
        lower.contains('furniture')) {
      return [
        GoalMilestone(percentage: 0.0, label: 'Blueprint for $cleanTitle', emoji: '🏠'),
        const GoalMilestone(percentage: 0.25, label: 'Security deposit saved', emoji: '🔑'),
        const GoalMilestone(percentage: 0.50, label: 'Furniture fund locked', emoji: '🛋️'),
        const GoalMilestone(percentage: 0.75, label: 'Housewarming prep', emoji: '🏡'),
        GoalMilestone(percentage: 1.0, label: 'Welcome to $cleanTitle!', emoji: '🔑'),
      ];
    }

    // 6. Fitness / Health
    if (lower.contains('gym') ||
        lower.contains('fit') ||
        lower.contains('health') ||
        lower.contains('marathon') ||
        lower.contains('cycle') ||
        lower.contains('run')) {
      return [
        const GoalMilestone(percentage: 0.0, label: 'Commitment made', emoji: '💪'),
        const GoalMilestone(percentage: 0.25, label: 'Gear & shoes ready', emoji: '👟'),
        const GoalMilestone(percentage: 0.50, label: 'Mid-goal streak', emoji: '🏋️'),
        const GoalMilestone(percentage: 0.75, label: 'Pass fully funded', emoji: '🧘'),
        GoalMilestone(percentage: 1.0, label: '$cleanTitle achieved!', emoji: '🏆'),
      ];
    }

    // 7. Events / Celebrations / Gifts
    if (lower.contains('party') ||
        lower.contains('concert') ||
        lower.contains('fest') ||
        lower.contains('birthday') ||
        lower.contains('wedding') ||
        lower.contains('gift') ||
        lower.contains('event')) {
      return [
        const GoalMilestone(percentage: 0.0, label: 'Save the date', emoji: '🎟️'),
        const GoalMilestone(percentage: 0.25, label: 'Passes booked', emoji: '🎫'),
        const GoalMilestone(percentage: 0.50, label: 'Travel & outfit set', emoji: '🥳'),
        const GoalMilestone(percentage: 0.75, label: 'VIP fund ready', emoji: '🥂'),
        GoalMilestone(percentage: 1.0, label: '$cleanTitle unlocked!', emoji: '🎉'),
      ];
    }

    // 8. Emergency / Savings / Investment
    if (lower.contains('save') ||
        lower.contains('saving') ||
        lower.contains('emergency') ||
        lower.contains('fund') ||
        lower.contains('invest') ||
        lower.contains('gold') ||
        lower.contains('stock')) {
      return [
        const GoalMilestone(percentage: 0.0, label: 'Safety net started', emoji: '🛡️'),
        const GoalMilestone(percentage: 0.25, label: 'First buffer built', emoji: '🏦'),
        GoalMilestone(percentage: 0.50, label: 'Halfway to $cleanTitle', emoji: '💰'),
        const GoalMilestone(percentage: 0.75, label: 'Major buffer set', emoji: '📊'),
        GoalMilestone(percentage: 1.0, label: '$cleanTitle secured!', emoji: '💎'),
      ];
    }

    // 9. General / Default Dynamic Fallback
    return [
      GoalMilestone(percentage: 0.0, label: 'First step for $cleanTitle', emoji: '🌱'),
      const GoalMilestone(percentage: 0.25, label: 'Building momentum', emoji: '🧱'),
      GoalMilestone(percentage: 0.50, label: 'Halfway to $cleanTitle', emoji: '🎯'),
      GoalMilestone(percentage: 0.75, label: 'Almost at $cleanTitle', emoji: '🚀'),
      GoalMilestone(percentage: 1.0, label: '$cleanTitle achieved!', emoji: '🏆'),
    ];
  }

  static Goal defaultGoaTrip() {
    return Goal(
      id: 'goa_trip',
      name: 'Goa Trip',
      emoji: '🏝️',
      targetAmount: 15000,
      currentAmount: 9000,
      targetDate: 'October',
      milestones: const [
        GoalMilestone(percentage: 0.0, label: 'Start saving', emoji: '🎒'),
        GoalMilestone(percentage: 0.25, label: 'Booked the bus', emoji: '🚌'),
        GoalMilestone(percentage: 0.50, label: 'Stay sorted', emoji: '🏨'),
        GoalMilestone(percentage: 0.75, label: 'Fun money set', emoji: '🍹'),
        GoalMilestone(percentage: 1.0, label: 'Goa, unlocked', emoji: '🎉'),
      ],
    );
  }
}
