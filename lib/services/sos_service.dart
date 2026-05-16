import 'package:flutter/services.dart';
import 'supabase_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  Future<void> makePhoneCall(String phoneNumber) async {
    try {
      const MethodChannel channel = MethodChannel('com.nestway/phone');
      await channel.invokeMethod('makePhoneCall', {'phoneNumber': phoneNumber});
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    }
  }

  Future<void> callEmergencyServices() async {
    await makePhoneCall('110');
  }

  Future<Map<String, double?>> getCurrentLocation() async {
    try {
      const MethodChannel channel = MethodChannel('com.nestway/location');
      final result = await channel.invokeMethod('getCurrentLocation');
      return {
        'latitude': result['latitude'] as double?,
        'longitude': result['longitude'] as double?,
      };
    } catch (e) {
      return {'latitude': null, 'longitude': null};
    }
  }

  String generateLocationShareUrl(double lat, double lng, String? description) {
    final encodedDesc = Uri.encodeComponent(description ?? '我的位置');
    return 'https://uri.amap.com/marker?position=$lng,$lat&name=$encodedDesc';
  }

  Future<bool> reportSosEvent({
    required String type,
    String? locationDescription,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await SupabaseService.instance
          .from('sos_logs')
          .insert({
        'type': type,
        'location_description': locationDescription,
        'latitude': latitude,
        'longitude': longitude,
      });

      return response.error == null;
    } catch (e) {
      return false;
    }
  }

  Future<void> shareLocation({
    required double latitude,
    required double longitude,
    required String description,
  }) async {
    final url = generateLocationShareUrl(latitude, longitude, description);
    await Clipboard.setData(ClipboardData(text: url));
  }

  Future<List<Map<String, dynamic>>> getSosHistory() async {
    try {
      final response = await SupabaseService.instance
          .from('sos_logs')
          .select()
          .order('triggered_at', ascending: false);

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final response = await SupabaseService.instance
          .from('emergency_contacts')
          .select()
          .order('sort_order');

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> triggerSos({
    required List<Map<String, dynamic>> emergencyContacts,
    String? locationDescription,
  }) async {
    final location = await getCurrentLocation();
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    final phone = emergencyContacts.isNotEmpty
        ? emergencyContacts.first['phone'] as String? ?? '110'
        : '110';

    await Future.wait([
      reportSosEvent(
        type: 'sos',
        locationDescription: locationDescription,
        latitude: latitude,
        longitude: longitude,
      ),
      makePhoneCall(phone),
      if (latitude != null && longitude != null)
        shareLocation(
          latitude: latitude,
          longitude: longitude,
          description: locationDescription ?? 'SOS 求助位置',
        ),
    ]);
  }
}