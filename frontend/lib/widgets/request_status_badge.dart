import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';

class RequestStatusBadge extends StatelessWidget {
  final RentalRequestStatus status;

  const RequestStatusBadge({super.key, required this.status});

  Color get _dotColor {
    switch (status) {
      case RentalRequestStatus.pending:
        return const Color(0xFFF5A623);
      case RentalRequestStatus.approved:
        return const Color(0xFF2E9D63);
      case RentalRequestStatus.rejected:
        return AppColors.error;
      case RentalRequestStatus.active:
        return AppColors.primary;
      case RentalRequestStatus.returnRequested:
        return const Color(0xFF7B61FF);
      case RentalRequestStatus.completed:
        return const Color(0xFF2E9D63);
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case RentalRequestStatus.pending:
        return AppColors.warningSoft;
      case RentalRequestStatus.approved:
      case RentalRequestStatus.completed:
        return const Color(0xFFEAF7F0);
      case RentalRequestStatus.rejected:
        return AppColors.errorSoft;
      case RentalRequestStatus.active:
        return AppColors.primarySoft;
      case RentalRequestStatus.returnRequested:
        return AppColors.purpleSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: _dotColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
