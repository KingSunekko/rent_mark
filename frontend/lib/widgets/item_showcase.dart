import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// RentMark's signature visual motif: a cluster of rounded tiles, each
/// holding a rentable-item icon (camera, drill, basketball, projector,
/// tent, speaker). This stands in for the "large visual/image area" from
/// the reference — but built from everyday rentable items, never houses,
/// since RentMark is item rental, not real estate.
class ItemShowcase extends StatelessWidget {
  final double height;

  const ItemShowcase({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Backing glow
          Container(
            width: height * 0.92,
            height: height * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primarySoft.withValues(alpha: 0.9),
                  AppColors.primarySoft.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Center hero tile
          Container(
            width: height * 0.46,
            height: height * 0.46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.terrain_rounded,
              color: Colors.white,
              size: 54,
            ),
          ),
          // Orbiting item tiles
          Positioned(
            left: 6,
            top: 8,
            child: _ItemTile(
              icon: Icons.camera_alt_rounded,
              size: height * 0.24,
            ),
          ),
          Positioned(
            right: 2,
            top: height * 0.06,
            child: _ItemTile(icon: Icons.speaker_rounded, size: height * 0.22),
          ),
          Positioned(
            left: height * 0.02,
            bottom: 4,
            child: _ItemTile(
              icon: Icons.sports_basketball_rounded,
              size: height * 0.2,
            ),
          ),
          Positioned(
            right: height * 0.04,
            bottom: 0,
            child: _ItemTile(icon: Icons.videocam_rounded, size: height * 0.24),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const _ItemTile({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: AppShadows.card,
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.48),
    );
  }
}
