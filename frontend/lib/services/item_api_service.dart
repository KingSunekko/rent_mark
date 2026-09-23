import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/owner_listing.dart';
import 'api_config.dart';
import 'auth_api_service.dart';

class ItemApiService {
  static const _timeout = Duration(seconds: 30);

  Future<List<OwnerListing>> listPublic(String token) async {
    const pageSize = 50;
    final items = <String, OwnerListing>{};
    for (var offset = 0; ; offset += pageSize) {
      final page = await listPublicPage(token, limit: pageSize, offset: offset);
      for (final item in page) {
        items[item.id] = item;
      }
      if (page.length < pageSize) return items.values.toList();
    }
  }

  Future<List<OwnerListing>> listPublicPage(
    String token, {
    required int limit,
    required int offset,
  }) async {
    final data = await requestJson(
      'GET',
      '/api/v1/items?limit=$limit&offset=$offset',
      token,
    );
    return (data as List<dynamic>)
        .map((value) => OwnerListing.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<List<OwnerListing>> listOwner(String token) async {
    final data = await requestJson('GET', '/api/v1/owner/items', token);
    return (data as List<dynamic>)
        .map((value) => OwnerListing.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerListing> create(
    String token,
    OwnerListing item,
    List<String> imagePaths,
  ) async {
    final data = await requestJson(
      'POST',
      '/api/v1/owner/items',
      token,
      body: item.toApiJson(imagePaths: imagePaths),
    );
    return OwnerListing.fromJson(data as Map<String, dynamic>);
  }

  Future<OwnerListing> update(
    String token,
    OwnerListing item,
    List<String> imagePaths,
  ) async {
    final data = await requestJson(
      'PATCH',
      '/api/v1/owner/items/${item.id}',
      token,
      body: item.toApiJson(imagePaths: imagePaths),
    );
    return OwnerListing.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String token, String id) async {
    await requestJson('DELETE', '/api/v1/owner/items/$id', token);
  }

  Future<void> cleanupImages(String token, List<String> paths) async {
    if (paths.isEmpty) return;
    await requestJson(
      'POST',
      '/api/v1/owner/items/images/cleanup',
      token,
      body: {'image_paths': paths},
    );
  }

  Future<UploadedItemImage> uploadImage(String token, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final imageType = detectSupportedImageType(bytes);
    if (imageType == null) {
      throw const ApiException(
        'This photo format is not supported. Choose a JPEG, PNG, or WebP image.',
      );
    }
    final originalName = file.uri.pathSegments.last;
    final originalStem = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final filename = '$originalStem.${imageType.extension}';
    final contentType = imageType.mimeType;
    final boundary = 'rentmark-${DateTime.now().microsecondsSinceEpoch}';
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client
          .postUrl(Uri.parse('${ApiConfig.baseUrl}/api/v1/owner/items/images'))
          .timeout(_timeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="image"; filename="$filename"\r\n',
      );
      request.write('Content-Type: $contentType\r\n\r\n');
      request.add(bytes);
      request.write('\r\n--$boundary--\r\n');
      final response = await request.close().timeout(_timeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_timeout);
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_detail(decoded), response.statusCode);
      }
      final result = decoded as Map<String, dynamic>;
      return UploadedItemImage(
        path: result['path'].toString(),
        url: result['url'].toString(),
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Image upload took too long. Please try again.');
    } on SocketException {
      throw const ApiException('Cannot reach the RentMark server.');
    } finally {
      client.close(force: true);
    }
  }

  /// Shared authenticated JSON transport for the incremental backend services.
  Future<dynamic> requestJson(
    String method,
    String path,
    String token, {
    Map<String, Object>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client
          .openUrl(method, Uri.parse('${ApiConfig.baseUrl}$path'))
          .timeout(_timeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(_timeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_timeout);
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_detail(decoded), response.statusCode);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The RentMark server took too long to respond.');
    } on SocketException {
      throw const ApiException('Cannot reach the RentMark server.');
    } on FormatException {
      throw const ApiException(
        'The RentMark server returned an invalid response.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _detail(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['detail']?.toString() ?? 'Request failed.';
    }
    return 'Request failed.';
  }
}

class UploadedItemImage {
  final String path;
  final String url;

  const UploadedItemImage({required this.path, required this.url});
}

class SupportedImageType {
  final String mimeType;
  final String extension;

  const SupportedImageType(this.mimeType, this.extension);
}

SupportedImageType? detectSupportedImageType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return const SupportedImageType('image/jpeg', 'jpg');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return const SupportedImageType('image/png', 'png');
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return const SupportedImageType('image/webp', 'webp');
  }
  return null;
}
