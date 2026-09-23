import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Skeleton placeholders shown briefly on Home/Search while mock data
/// "loads". Purely visual — no real network request backs it.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.5 + (_controller.value * 0.3);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Skeleton matching the large "Near You" [ItemCard] silhouette.
class SkeletonLargeCard extends StatelessWidget {
  const SkeletonLargeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 250, height: 165, radius: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 80, height: 11),
                const SizedBox(height: 10),
                const SkeletonBox(width: 110, height: 12),
                const SizedBox(height: 10),
                const SkeletonBox(width: 130, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching the [CompactItemCard] row silhouette.
class SkeletonCompactCard extends StatelessWidget {
  const SkeletonCompactCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 56, height: 56, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 13),
                const SizedBox(height: 8),
                const SkeletonBox(width: 70, height: 11),
                const SizedBox(height: 8),
                const SkeletonBox(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
