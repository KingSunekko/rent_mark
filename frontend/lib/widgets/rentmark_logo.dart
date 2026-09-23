import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The RentMark mark: a rounded blue tile with a "tag" glyph, paired with
/// the wordmark. Used on Splash, Welcome, and (compact) on auth screens.
class RentMarkLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  const RentMarkLogo({
    super.key,
    this.size = 56,
    this.showWordmark = true,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.32),
            gradient: const LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            Icons.sync_alt_rounded,
            color: Colors.white,
            size: size * 0.52,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.28),
          Text(
            'RentMark',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: wordmarkColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
