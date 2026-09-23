import 'rental_item.dart';
import 'rental_pricing.dart';
import 'owner_listing.dart';

/// Status of a rental request across the renter/owner flow.
/// Statuses for the complete request, active-rental, and return lifecycle.
enum RentalRequestStatus {
  pending,
  approved,
  rejected,
  active,
  returnRequested,
  completed,
}

extension RentalRequestStatusLabel on RentalRequestStatus {
  String get label {
    switch (this) {
      case RentalRequestStatus.pending:
        return 'Pending';
      case RentalRequestStatus.approved:
        return 'Approved';
      case RentalRequestStatus.rejected:
        return 'Rejected';
      case RentalRequestStatus.active:
        return 'Active';
      case RentalRequestStatus.returnRequested:
        return 'Return Requested';
      case RentalRequestStatus.completed:
        return 'Completed';
    }
  }

  String get description {
    switch (this) {
      case RentalRequestStatus.pending:
        return 'Waiting for the owner to review your request.';
      case RentalRequestStatus.approved:
        return 'Approved by the owner. Waiting for the rental to start.';
      case RentalRequestStatus.rejected:
        return 'The owner rejected this rental request.';
      case RentalRequestStatus.active:
        return 'Rental is currently active.';
      case RentalRequestStatus.returnRequested:
        return 'The renter marked the item as ready to return.';
      case RentalRequestStatus.completed:
        return 'The owner confirmed the item was returned.';
    }
  }
}

/// A submitted rental request, including authoritative backend snapshots.
class RentalRequest {
  final String id;
  final RentalItem item;
  final bool isRemote;
  final int? serverTotalCentavos;
  final String renterName;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final String message;
  final String pickupMethod;
  RentalRequestStatus status;
  String rejectionReason;
  final DateTime requestedAt;
  DateTime? approvedAt;
  DateTime? rejectedAt;
  DateTime? startedAt;
  DateTime? returnRequestedAt;
  DateTime? completedAt;

  RentalRequest({
    required this.id,
    required this.item,
    this.isRemote = false,
    this.serverTotalCentavos,
    required this.renterName,
    this.renterId = '',
    this.ownerId = '',
    required this.startDate,
    required this.endDate,
    required this.message,
    this.pickupMethod = 'Community meetup',
    this.status = RentalRequestStatus.pending,
    this.rejectionReason = '',
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.startedAt,
    this.returnRequestedAt,
    this.completedAt,
  });

  /// Inclusive day count between start and end (e.g. Sep 5 → Sep 7 = 3).
  int get durationDays => endDate.difference(startDate).inDays + 1;

  double get estimatedTotal => serverTotalCentavos != null
      ? serverTotalCentavos! / 100
      : item.totalForDays(durationDays);

  factory RentalRequest.fromJson(Map<String, dynamic> json) => RentalRequest(
    id: json['id'] as String,
    item: OwnerListing.fromJson(json['item_snapshot'] as Map<String, dynamic>)
        .toRentalItem(),
    isRemote: true,
    serverTotalCentavos: json['total_centavos'] as int,
    renterName: json['renter_name'] as String,
    renterId: json['renter_id'] as String,
    ownerId: json['owner_id'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    endDate: DateTime.parse(json['end_date'] as String),
    message: json['message'] as String,
    pickupMethod: json['pickup_method'] as String,
    status: json['status'] == 'return_requested'
        ? RentalRequestStatus.returnRequested
        : RentalRequestStatus.values.byName(json['status'] as String),
    requestedAt: DateTime.parse(json['requested_at'] as String).toLocal(),
    rejectionReason: json['rejection_reason'] as String? ?? '',
    approvedAt: _optionalDate(json['approved_at']),
    rejectedAt: _optionalDate(json['rejected_at']),
    startedAt: _optionalDate(json['started_at']),
    returnRequestedAt: _optionalDate(json['return_requested_at']),
    completedAt: _optionalDate(json['completed_at']),
  );

  static DateTime? _optionalDate(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  String get estimatedTotalLabel => formatPesos(estimatedTotal);

  String get durationLabel =>
      '$durationDays ${durationDays == 1 ? 'day' : 'days'}';

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get rentalPeriodLabel {
    final start = '${_shortMonths[startDate.month - 1]} ${startDate.day}';
    final end = '${_shortMonths[endDate.month - 1]} ${endDate.day}';
    return '$start – $end';
  }
}
