import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Loads [imageUrl] for an item card and falls back to a clean
/// icon-on-tint tile if the URL is null, still loading past a brief
/// placeholder, or fails outright. Every card type (large, featured,
/// compact) uses this so image handling lives in one place and layout
/// never breaks because of a missing photo.
class ItemImage extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const ItemImage({
    super.key,
    required this.imageUrl,
    required this.icon,
    required this.height,
    this.width,
    this.borderRadius,
  });

  Widget _fallback({double iconScale = 0.42}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: height * iconScale, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: _fallback());
    }

    final isNetworkImage =
        imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://');

    return ClipRRect(
      borderRadius: radius,
      child: isNetworkImage
          ? Image.network(
              imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _loading();
              },
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : Image.file(
              File(imageUrl!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            ),
    );
  }

  Widget _loading() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primarySofter,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
