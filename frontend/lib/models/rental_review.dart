class RentalReview {
  final String id;
  final String rentalId;
  final String itemId;
  final String itemName;
  final String renterName;
  final String ownerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String renterId;
  final String ownerId;
  final bool isRemote;

  const RentalReview({
    required this.id,
    required this.rentalId,
    required this.itemId,
    required this.itemName,
    required this.renterName,
    required this.ownerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.renterId = '',
    this.ownerId = '',
    this.isRemote = false,
  });

  factory RentalReview.fromJson(Map<String, dynamic> json) => RentalReview(
    id: json['id'].toString(),
    rentalId: json['rental_request_id'].toString(),
    itemId: json['item_id'].toString(),
    itemName: json['item_name'].toString(),
    renterName: json['renter_name'].toString(),
    ownerName: json['owner_name'].toString(),
    rating: json['rating'] as int,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    renterId: json['renter_id'].toString(),
    ownerId: json['owner_id'].toString(),
    isRemote: true,
  );
}
