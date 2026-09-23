import '../models/owner_listing.dart';
import '../models/rental_request.dart';
import '../models/rental_review.dart';
import '../models/user_role.dart';
import 'item_api_service.dart';

class AdminSnapshot {
  final List<MockUser> users;
  final List<OwnerListing> listings;
  final List<RentalRequest> requests;
  final List<RentalReview> reviews;
  final Map<String, int> metrics;
  final Set<String> suspendedEmails;
  const AdminSnapshot(
    this.users,
    this.listings,
    this.requests,
    this.reviews,
    this.metrics,
    this.suspendedEmails,
  );
}

class AdminApiService {
  final ItemApiService _transport;
  AdminApiService({ItemApiService? transport})
    : _transport = transport ?? ItemApiService();

  Future<AdminSnapshot> dashboard(String token) async {
    final data = await _transport.requestJson(
      'GET',
      '/api/v1/admin/dashboard',
      token,
    ) as Map<String, dynamic>;
    final userRows = (data['users'] as List).cast<Map<String, dynamic>>();
    final users = userRows.map((row) {
      return MockUser(
        id: row['id'].toString(),
        name: row['name'].toString(),
        email: row['email'].toString(),
        role: UserRole.values.byName(row['role'].toString()),
        community: row['community'].toString(),
        phone: row['phone'] as String? ?? '',
        bio: row['bio'] as String? ?? '',
      );
    }).toList();
    return AdminSnapshot(
      users,
      (data['listings'] as List)
          .map((v) => OwnerListing.fromJson(v as Map<String, dynamic>))
          .toList(),
      (data['rentals'] as List)
          .map((v) => RentalRequest.fromJson(v as Map<String, dynamic>))
          .toList(),
      (data['reviews'] as List)
          .map((v) => RentalReview.fromJson(v as Map<String, dynamic>))
          .toList(),
      (data['metrics'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      userRows
          .where((row) => row['is_suspended'] == true)
          .map((row) => row['email'].toString())
          .toSet(),
    );
  }

  Future<void> moderateUser(
    String token,
    String id,
    bool suspended,
    String reason,
  ) async {
    await _transport.requestJson(
      'PATCH',
      '/api/v1/admin/users/$id',
      token,
      body: {'is_suspended': suspended, 'reason': reason},
    );
  }

  Future<void> moderateItem(
    String token,
    String id,
    bool hidden,
    String reason,
  ) async {
    await _transport.requestJson(
      'PATCH',
      '/api/v1/admin/items/$id',
      token,
      body: {
        'moderation_status': hidden ? 'hidden' : 'active',
        'reason': reason,
      },
    );
  }
}
