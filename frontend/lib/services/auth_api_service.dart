import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/user_role.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class AuthApiService {
  static const _requestTimeout = Duration(seconds: 20);

  String? accessToken;
  String? refreshToken;

  Future<MockUser> login(String email, String password) {
    _requireConfigured();
    return _authenticate('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<MockUser> register({
    required String email,
    required String password,
    required String name,
    required String community,
    required UserRole role,
  }) {
    _requireConfigured();
    return _authenticate('/api/v1/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'community': community,
      'role': role.name,
    });
  }

  void _requireConfigured() {
    if (!ApiConfig.enabled) {
      throw const ApiException(
        'RentMark is not configured. Start with --dart-define=API_BASE_URL=http://YOUR_PC_IP:8000.',
      );
    }
  }

  Future<MockUser> updateProfile({
    required String name,
    required String community,
    required String phone,
    required String bio,
  }) async {
    final token = accessToken;
    if (token == null) throw const ApiException('Authentication required.');
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .patchUrl(Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'))
          .timeout(_requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(
        jsonEncode({
          'name': name,
          'community': community,
          'phone': phone,
          'bio': bio,
        }),
      );
      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);
      final decoded = jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded is Map
              ? decoded['detail']?.toString() ?? 'Request failed.'
              : 'Request failed.',
          response.statusCode,
        );
      }
      return _userFromJson(decoded as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The RentMark server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const ApiException('Cannot reach the RentMark server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<MockUser> _authenticate(String path, Map<String, Object> body) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .postUrl(Uri.parse('${ApiConfig.baseUrl}$path'))
          .timeout(_requestTimeout);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);
      final decoded = jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded is Map
              ? decoded['detail']?.toString() ?? 'Request failed.'
              : 'Request failed.',
          response.statusCode,
        );
      }
      final data = decoded as Map<String, dynamic>;
      accessToken = data['access_token'] as String;
      refreshToken = data['refresh_token'] as String;
      return _userFromJson(data['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The RentMark server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const ApiException('Cannot reach the RentMark server.');
    } on HttpException {
      throw const ApiException('The RentMark server closed the connection.');
    } on FormatException {
      throw const ApiException(
        'The RentMark server returned an invalid response.',
      );
    } finally {
      client.close(force: true);
    }
  }

  MockUser _userFromJson(Map<String, dynamic> user) => MockUser(
    id: user['id'] as String,
    name: user['name'] as String,
    email: user['email'] as String,
    role: UserRole.values.byName(user['role'] as String),
    community: user['community'] as String,
    phone: user['phone'] as String? ?? '',
    bio: user['bio'] as String? ?? '',
    joinedAt: DateTime.tryParse(user['created_at'] as String? ?? ''),
  );

  void clearSession() {
    accessToken = null;
    refreshToken = null;
  }
}
