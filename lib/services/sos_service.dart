import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';
import 'location_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  int? _currentUserId;

  int? get currentUserId => _currentUserId;
  set currentUserId(int? value) => _currentUserId = value;

  static const _edgeFunctionUrl =
      'https://fbnctnhjcjkbmmvcuqxh.supabase.co/functions/v1/send-sos-sms';
  // 与 supabase secrets set FUNCTION_SECRET 保持一致
  static const _edgeFunctionSecret = 'nestway-sos-sms-2026';

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
    // Cold backup: try native MethodChannel, then fall back to LocationService
    try {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        const MethodChannel channel = MethodChannel('com.nestway/location');
        final result = await channel.invokeMethod('getCurrentLocation');
        if (result['latitude'] != null && result['longitude'] != null) {
          return {
            'latitude': result['latitude'] as double?,
            'longitude': result['longitude'] as double?,
          };
        }
      }
    } catch (_) {
      // MethodChannel not implemented, fall through to LocationService
    }

    final loc = await LocationService().getPreciseLocation();
    return {
      'latitude': loc.latitude,
      'longitude': loc.longitude,
    };
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
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

  Future<String> getUserDisplayName() async {
    if (_currentUserId == null) return '用户';
    try {
      print('🔧 查询用户信息，user_id=$_currentUserId');
      
      final response = await SupabaseService.instance
          .from('users')
          .select('*')
          .eq('id', _currentUserId!)
          .maybeSingle();
      
      print('🔧 查询结果: $response');
      
      if (response != null) {
        final name = response['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (e, stackTrace) {
      print('❌ 获取用户名失败: $e');
      print('❌ Stack trace: $stackTrace');
    }
    return '用户';
  }

  Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
    final loc = await LocationService().getPreciseLocation();
    return {
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'address': loc.address,
    };
  }

  Future<bool> sendSosSms({
    required List<String> phones,
    required String name,
    required String location,
    String? coords,
  }) async {
    try {
      // 将坐标信息合并到位置描述中
      final locationWithCoords = coords != null && coords.isNotEmpty
          ? '$location（$coords）'
          : location;

      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_edgeFunctionSecret',
        },
        body: json.encode({
          'phones': phones,
          'name': name,
          'location': locationWithCoords,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ SOS短信已发送给 ${data['sentTo']} 个联系人');
          return true;
        }
      }

      print('❌ 短信发送失败: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      print('❌ 短信发送异常: $e');
      return false;
    }
  }

  Future<void> triggerSos({
    required List<Map<String, dynamic>> emergencyContacts,
    String? locationDescription,
  }) async {
    final location = await getCurrentLocationWithAddress();
    final latitude = location['latitude'] as double?;
    final longitude = location['longitude'] as double?;
    final address = location['address'] as String?;

    final phone = emergencyContacts.isNotEmpty
        ? emergencyContacts.first['phone'] as String? ?? '110'
        : '110';

    final tasks = <Future>[
      reportSosEvent(
        type: 'sos',
        locationDescription: locationDescription ?? address,
        latitude: latitude,
        longitude: longitude,
      ),
      makePhoneCall(phone),
      if (latitude != null && longitude != null)
        shareLocation(
          latitude: latitude,
          longitude: longitude,
          description: locationDescription ?? address ?? 'SOS 求助位置',
        ),
    ];

    // 发送 SOS 短信给所有紧急联系人
    if (emergencyContacts.isNotEmpty) {
      final phones = emergencyContacts
          .map((c) => c['phone'] as String?)
          .whereType<String>()
          .toList();
      final name = await getUserDisplayName();
      final coords = (latitude != null && longitude != null)
          ? '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}'
          : null;
      tasks.add(sendSosSms(
        phones: phones,
        name: name,
        location: address ?? locationDescription ?? '未知位置',
        coords: coords,
      ));
    }

    await Future.wait(tasks);
  }

  /// 超时自动通知紧急联系人
  Future<void> sendTimeoutAlert({
    required List<String> phones,
    required LocationPoint lastLocation,
    required String userName,
  }) async {
    await sendSosSms(
      phones: phones,
      name: userName,
      location: lastLocation.address ?? '未知位置',
      coords:
          '${lastLocation.latitude.toStringAsFixed(6)},${lastLocation.longitude.toStringAsFixed(6)}',
    );

    await reportSosEvent(
      type: 'escort_timeout',
      locationDescription: lastLocation.address,
      latitude: lastLocation.latitude,
      longitude: lastLocation.longitude,
    );
  }

  /// 超时后用户确认安全，发送解释短信
  Future<void> sendSafetyExplanation({
    required List<String> phones,
    required String userName,
  }) async {
    await sendSosSms(
      phones: phones,
      name: userName,
      location: '用户已确认安全，仅为超时未及时打卡，无需担心。',
      coords: null,
    );
  }
}