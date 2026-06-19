import 'package:flutter/services.dart';

class GoogleServicesService {
  static const _channel = MethodChannel('com.cities_offline_app/google_services');
  static bool? _cached;

  static Future<bool> hasGoogleServices() async {
    if (_cached != null) return _cached!;
    _cached = await _channel.invokeMethod('hasGoogleServices');
    return _cached!;
  }
}
