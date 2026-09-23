import 'package:flutter/services.dart';

class MapsService {
  static const _channel = MethodChannel('rentmark/maps');
  static Future<bool> openMeetingPoint(String query) async {
    if (query.trim().isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('openSearch', {
            'query': query.trim(),
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
