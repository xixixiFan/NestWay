import 'package:flutter/services.dart';
import 'supabase_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  int? _currentUserId;

  int? get currentUserId => _currentUserId;
  set currentUserId(int? value) => _currentUserId = value;

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
    if (_currentUserId == null) {
      print('⚠️ 未登录，跳过 SOS 事件上报');
      return false;
    }
    try {
      print('🔧 上报 SOS 事件: type=$type, location=$locationDescription');

      await SupabaseService.instance
          .from('sos_logs')
          .insert({
        'user_id': _currentUserId,
        'type': type,
        'location_description': locationDescription,
        'latitude': latitude,
        'longitude': longitude,
      });

      print('✅ SOS 事件上报成功!');
      return true;
    } catch (e, stackTrace) {
      print('❌ 上报失败: $e');
      print('❌ Stack trace: $stackTrace');
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
    if (_currentUserId == null) {
      print('⚠️ 未登录，返回空 SOS 历史');
      return [];
    }
    try {
      print('🔧 获取 SOS 历史 (user_id=$_currentUserId)...');

      final response = await SupabaseService.instance
          .from('sos_logs')
          .select()
          .eq('user_id', _currentUserId!)
          .order('triggered_at', ascending: false);

      print('✅ 成功获取 ${response.length} 条 SOS 记录');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e, stackTrace) {
      print('❌ 获取 SOS 历史失败: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    if (_currentUserId == null) {
      print('⚠️ 未登录，返回空联系人列表');
      return [];
    }
    try {
      print('🔧 获取紧急联系人 (user_id=$_currentUserId)...');

      final response = await SupabaseService.instance
          .from('emergency_contacts')
          .select()
          .eq('user_id', _currentUserId!)
          .order('sort_order');

      print('✅ 成功获取 ${response.length} 个紧急联系人');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e, stackTrace) {
      print('❌ 获取紧急联系人失败: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> addEmergencyContact({
    required String name,
    required String phone,
  }) async {
    if (_currentUserId == null) {
      print('⚠️ 未登录，无法添加联系人');
      return false;
    }
    try {
      print('🔧 正在添加联系人: name=$name, phone=$phone');

      // 获取当前最大排序号
      final contacts = await getEmergencyContacts();
      final maxSortOrder = contacts.isNotEmpty
          ? contacts.map((c) => c['sort_order'] as int).reduce((a, b) => a > b ? a : b)
          : 0;
      final newSortOrder = maxSortOrder + 1;

      await SupabaseService.instance
          .from('emergency_contacts')
          .insert({
        'user_id': _currentUserId,
        'name': name,
        'phone': phone,
        'sort_order': newSortOrder,
      });

      print('✅ 联系人添加成功! user_id=$_currentUserId, sort_order=$newSortOrder');
      return true;
    } catch (e, stackTrace) {
      print('❌ 添加失败: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> updateEmergencyContact({
    required int id,
    required String name,
    required String phone,
  }) async {
    try {
      print('🔧 更新联系人: id=$id, name=$name, phone=$phone');
      
      await SupabaseService.instance
          .from('emergency_contacts')
          .update({
        'name': name,
        'phone': phone,
      })
          .eq('id', id);

      print('✅ 联系人更新成功!');
      return true;
    } catch (e, stackTrace) {
      print('❌ 更新失败: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(int id) async {
    try {
      print('🔧 删除联系人: id=$id');
      
      await SupabaseService.instance
          .from('emergency_contacts')
          .delete()
          .eq('id', id);

      print('✅ 联系人删除成功!');
      return true;
    } catch (e, stackTrace) {
      print('❌ 删除失败: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
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