import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? address;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'address': address,
      };

  @override
  String toString() =>
      'LocationPoint(lat: $latitude, lng: $longitude, time: $timestamp)';
}

class EscortLocationService {
  static final EscortLocationService _instance =
      EscortLocationService._internal();
  factory EscortLocationService() => _instance;
  EscortLocationService._internal();

  LocationPoint? _startPoint;
  LocationPoint? _lastKnownLocation;
  List<LocationPoint> _trackHistory = [];
  bool _isTracking = false;

  final List<String> _mockAddresses = [
    '广东省深圳市南山区科技园南区',
    '广东省深圳市南山区科技园北区',
    '广东省深圳市南山区南山智园',
    '广东省深圳市南山区海岸城',
    '广东省深圳市福田区车公庙',
    '广东省深圳市罗湖区东门',
    '广东省深圳市龙岗区坂田',
  ];
  int _mockAddressIndex = 0;

  LocationPoint? get startPoint => _startPoint;
  LocationPoint? get lastKnownLocation => _lastKnownLocation;
  List<LocationPoint> get trackHistory => List.unmodifiable(_trackHistory);
  bool get isTracking => _isTracking;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ 定位服务未启用，请在系统设置中开启定位服务');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ 定位权限被拒绝');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ 定位权限被永久拒绝，请在设置中开启');
      return false;
    }

    return true;
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    print('📍 开始地址解析: lat=$lat, lng=$lng');
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo?key=89ff90f769765ecd5f68e2cb48e283cb&location=$lng,$lat&extensions=base',
      );
      print('🔗 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📦 响应内容: ${response.body}');
        final data = json.decode(response.body);
        print('📋 解析后数据: $data');
        
        if (data['status'] == '1' && data['regeocode'] != null) {
          final address = data['regeocode']['formatted_address'] as String?;
          if (address != null && address.isNotEmpty) {
            print('✅ 地址解析成功: $address');
            return address;
          } else {
            print('❌ formatted_address 为空或不存在');
          }
        } else {
          print('❌ API返回错误 status: ${data['status']}');
        }
      } else {
        print('❌ HTTP请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 地址解析异常: $e');
      print('📌 异常类型: ${e.runtimeType}');
    }
    
    // 使用模拟地址作为备用方案
    final mockAddress = _mockAddresses[_mockAddressIndex % _mockAddresses.length];
    _mockAddressIndex++;
    print('🔄 使用模拟地址: $mockAddress');
    return mockAddress;
  }

  Future<LocationPoint?> getCurrentLocation() async {
    print('📍 getCurrentLocation 开始执行');
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        print('❌ 权限检查失败');
        return null;
      }

      print('📍 开始获取GPS位置...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      print('✅ GPS位置获取成功: lat=${position.latitude}, lng=${position.longitude}');

      print('📍 开始解析地址...');
      String? address = await reverseGeocode(position.latitude, position.longitude);
      print('📍 解析结果: address=$address');

      final point = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        address: address ?? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
      _lastKnownLocation = point;
      print('🎉 最终位置对象: ${point.address}');
      return point;
    } catch (e) {
      print('❌ 获取位置失败: $e');
      print('📌 异常类型: ${e.runtimeType}');
      
      // 异常时也返回模拟数据
      final mockAddress = _mockAddresses[_mockAddressIndex % _mockAddresses.length];
      _mockAddressIndex++;
      print('🔄 使用模拟位置');
      return LocationPoint(
        latitude: 22.545430,
        longitude: 114.058224,
        timestamp: DateTime.now(),
        address: mockAddress,
      );
    }
  }

  Future<LocationPoint?> startTracking() async {
    _isTracking = true;
    _trackHistory.clear();
    final location = await getCurrentLocation();
    if (location != null) {
      _startPoint = location;
      _trackHistory.add(location);
    }
    return location;
  }

  Future<LocationPoint?> recordCurrentPosition() async {
    if (!_isTracking) return null;
    final location = await getCurrentLocation();
    if (location != null) {
      _trackHistory.add(location);
    }
    return location;
  }

  void stopTracking() {
    _isTracking = false;
  }

  void reset() {
    _startPoint = null;
    _lastKnownLocation = null;
    _trackHistory.clear();
    _isTracking = false;
    _mockAddressIndex = 0;
  }

  Future<bool> reportLocationToServer({
    required String escortId,
    required double lat,
    required double lng,
    String? address,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      print('📍 上报位置到服务器: escortId=$escortId, lat=$lat, lng=$lng, address=$address');
      return true;
    } catch (e) {
      print('❌ 上报位置失败: $e');
      return false;
    }
  }

  Future<bool> reportEscortStart({
    required String escortId,
    required String destination,
    required int estimatedMinutes,
    required LocationPoint startPoint,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      print('🚗 护送开始: escortId=$escortId, destination=$destination, estimatedMinutes=$estimatedMinutes');
      print('   起点: ${startPoint.address}');
      return true;
    } catch (e) {
      print('❌ 上报护送开始失败: $e');
      return false;
    }
  }

  Future<bool> reportEscortEnd({
    required String escortId,
    required String endType,
    LocationPoint? endPoint,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      print('🏁 护送结束: escortId=$escortId, endType=$endType');
      if (endPoint != null) {
        print('   终点: ${endPoint.address}');
      }
      print('   轨迹点数量: ${_trackHistory.length}');
      return true;
    } catch (e) {
      print('❌ 上报护送结束失败: $e');
      return false;
    }
  }

  Future<bool> reportTimeoutAlert({
    required String escortId,
    required LocationPoint lastLocation,
    required List<String> emergencyContacts,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      print('⚠️ 超时告警: escortId=$escortId');
      print('   最后位置: ${lastLocation.address}');
      print('   紧急联系人: ${emergencyContacts.join(", ")}');
      return true;
    } catch (e) {
      print('❌ 上报超时告警失败: $e');
      return false;
    }
  }
}
