import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Local-only favorite toggle — ♡ ↔ ♥. Used on card thumbnails (small,
/// over the image) and on the Item Details gallery (slightly larger).
/// No persistence; state lives wherever this is placed.
class FavoriteButton extends StatelessWidget {
  final bool favorited;
  final VoidCallback onTap;
  final double size;

  const FavoriteButton({
    super.key,
    required this.favorited,
    required this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
        ),
        child: Icon(
          favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size * 0.5,
          color: favorited ? AppColors.error : AppColors.textPrimary,
        ),
      ),
    );
  }
}
