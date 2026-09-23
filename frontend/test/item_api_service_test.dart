import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/services/item_api_service.dart';

void main() {
  test('detects supported image types from their bytes', () {
    expect(
      detectSupportedImageType([0xff, 0xd8, 0xff])?.mimeType,
      'image/jpeg',
    );
    expect(
      detectSupportedImageType([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
          ?.mimeType,
      'image/png',
    );
    expect(
      detectSupportedImageType([
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x45,
        0x42,
        0x50,
      ])?.mimeType,
      'image/webp',
    );
  });

  test('rejects unsupported image bytes', () {
    expect(detectSupportedImageType([0, 1, 2, 3]), isNull);
  });
}
