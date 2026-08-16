import 'package:flutter/material.dart';

/// Maps category name → [IconData] from Material Icons (bundled with Flutter).
const _categoryIcons = {
  'Food': Icons.restaurant_rounded,
  'Transit': Icons.directions_transit_filled_rounded,
  'Fun': Icons.movie_rounded,
  'Shopping': Icons.shopping_bag_rounded,
  'Bills': Icons.receipt_long_rounded,
  'Health': Icons.favorite_rounded,
  'Other': Icons.grid_view_rounded,
};

/// Maps category name → icon color that complements the card color.
const _categoryIconColors = {
  'Food': Color(0xFF8B3A1A),
  'Transit': Color(0xFF2A4A7A),
  'Fun': Color(0xFF2A5C2A),
  'Shopping': Color(0xFF7A5A00),
  'Bills': Color(0xFF5A4A3A),
  'Health': Color(0xFF1A5A4A),
  'Other': Color(0xFF5A4A3A),
};

/// Renders a Material icon for a known category, or the emoji string as
/// fallback [Text] for unknown categories.
class CategoryIcon extends StatelessWidget {
  final String category;
  final String emoji;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    required this.emoji,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _categoryIcons[category];
    if (iconData != null) {
      final iconColor =
          _categoryIconColors[category] ?? const Color(0xFF5A4A3A);
      return Icon(iconData, size: size, color: iconColor);
    }
    return Text(emoji, style: TextStyle(fontSize: size * 0.85));
  }
}
