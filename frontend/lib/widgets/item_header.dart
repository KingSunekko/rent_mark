import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Item name with category + rating beneath it — "Canon EOS Camera /
/// Electronics · ★ 4.8". Name is the dominant element per the info
/// hierarchy.
class ItemHeader extends StatelessWidget {
  final String name;
  final String category;
  final double rating;

  const ItemHeader({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text('·', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
