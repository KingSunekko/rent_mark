import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact header for the Item Discovery (Home) screen — "Find what you
/// need." as the headline, location beneath it, small avatar and
/// notification icon on the trailing side. Kept short in height so items
/// stay the visual focus of the screen.
class ItemDiscoveryHeader extends StatelessWidget {
  final String community;
  final String userName;
  final Uint8List? profileImageBytes;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const ItemDiscoveryHeader({
    super.key,
    required this.community,
    required this.userName,
    this.profileImageBytes,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find what you need.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    community,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: onNotificationTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySofter,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onAvatarTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: profileImageBytes != null
                  ? Image.memory(
                      profileImageBytes!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
