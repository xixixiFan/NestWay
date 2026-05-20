import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Unified location result returned by [LocationService].
class LocationResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy; // GPS accuracy radius in meters, smaller is better
  final String? address;
  final String? errorMessage; // null means success
  final bool needOpenGps; // true = UI should guide user to enable GPS

  LocationResult({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
    this.errorMessage,
    this.needOpenGps = false,
  });

  bool get isSuccess => latitude != null && longitude != null;
}

/// Location tracking point (used by escort module).
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

// ──────────────────────────────────────────────────
// Unified precision location (shared by SOS + escort)
// ──────────────────────────────────────────────────

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const _timeLimit = Duration(seconds: 25);
  static const _sampleCount = 3;
  static const _amapApiKey = '89ff90f769765ecd5f68e2cb48e283cb';

  /// Main entry: get precise location with multi-sampling.
  /// Returns [LocationResult] with address from reverse geocoding.
  Future<LocationResult> getPreciseLocation() async {
    print('[定位] === getPreciseLocation 开始 ===');

    // 1. Check if system GPS is enabled
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    print('[定位] GPS 服务状态: $gpsEnabled');
    if (!gpsEnabled) {
      print('[定位] ❌ GPS 未开启，返回 needOpenGps');
      return LocationResult(
        errorMessage: '请开启手机定位服务',
        needOpenGps: true,
      );
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    print('[定位] 定位权限: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('[定位] 请求权限后: $permission');
      if (permission == LocationPermission.denied) {
        print('[定位] ❌ 权限被拒绝');
        return LocationResult(errorMessage: '定位权限被拒绝');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('[定位] ❌ 权限被永久拒绝');
      return LocationResult(
        errorMessage: '定位权限已被永久拒绝，请在系统设置中开启',
        needOpenGps: true,
      );
    }

    // 3. Multi-sampling: collect N points, pick best accuracy
    print('[定位] 开始多采样 (目标 $_sampleCount 个点, 超时 ${_timeLimit.inSeconds}s)...');
    final samples = <Position>[];
    StreamSubscription<Position>? subscription;
    final completer = Completer<void>();

    try {
      subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: _timeLimit,
        ),
      ).listen(
        (position) {
          samples.add(position);
          print('[定位]   收到第 ${samples.length} 个采样: lat=${position.latitude.toStringAsFixed(6)} lng=${position.longitude.toStringAsFixed(6)} accuracy=${position.accuracy}m');
          if (samples.length >= _sampleCount) {
            completer.complete();
          }
        },
        onError: (e) {
          print('[定位] 流错误: $e');
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          print('[定位] 流结束, 共收到 ${samples.length} 个采样');
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );

      try {
        await completer.future.timeout(_timeLimit);
      } on TimeoutException {
        print('[定位] 采样超时 (${_timeLimit.inSeconds}s), 已收集 ${samples.length} 个点');
      }
    } catch (e) {
      print('[定位] 采样异常: $e');
    } finally {
      await subscription?.cancel();
    }

    // 4. Pick best sample by accuracy
    Position? bestPosition;
    if (samples.isNotEmpty) {
      samples.sort((a, b) => (a.accuracy).compareTo(b.accuracy));
      bestPosition = samples.first;
      print('[定位] 从 ${samples.length} 个采样中取最优: accuracy=${bestPosition.accuracy}m');
    } else {
      print('[定位] 无采样, 回退到单次 getCurrentPosition...');
      try {
        bestPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        print('[定位] 单次定位结果: lat=${bestPosition.latitude.toStringAsFixed(6)} lng=${bestPosition.longitude.toStringAsFixed(6)} accuracy=${bestPosition.accuracy}m');
      } catch (e) {
        print('[定位] ❌ 单次定位也失败: $e');
        return LocationResult(errorMessage: '无法获取当前位置，请确认定位服务已开启');
      }
    }

    // 5. Reverse geocode
    print('[定位] 最终坐标: lat=${bestPosition!.latitude.toStringAsFixed(6)} lng=${bestPosition.longitude.toStringAsFixed(6)}');
    String? address = await _reverseGeocode(
      bestPosition.latitude,
      bestPosition.longitude,
    );
    print('[定位] 逆地理编码结果: ${address ?? "(null)"}');

    final result = LocationResult(
      latitude: bestPosition.latitude,
      longitude: bestPosition.longitude,
      accuracy: bestPosition.accuracy,
      address: address,
    );
    print('[定位] === getPreciseLocation 返回: lat=${result.latitude?.toStringAsFixed(6)} lng=${result.longitude?.toStringAsFixed(6)} accuracy=${result.accuracy}m address="${result.address ?? "(null)"}" ===');
    return result;
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    print('[逆地理] 请求高德API: lat=$lat lng=$lng');
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo?key=$_amapApiKey&location=$lng,$lat&extensions=base',
      );
      final response = await http.get(url);
      print('[逆地理] HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[逆地理] API status=${data['status']}');
        if (data['status'] == '1' && data['regeocode'] != null) {
          final addr = data['regeocode']['formatted_address'] as String?;
          print('[逆地理] 地址: $addr');
          return addr;
        }
        print('[逆地理] API返回异常: ${data['info']}');
      }
    } catch (e) {
      print('[逆地理] 异常: $e');
    }
    print('[逆地理] 返回 null');
    return null;
  }
}

// ──────────────────────────────────────────────────
// Escort tracking service (delegates positioning to LocationService)
// ──────────────────────────────────────────────────

class EscortLocationService {
  static final EscortLocationService _instance =
      EscortLocationService._internal();
  factory EscortLocationService() => _instance;
  EscortLocationService._internal();

  final LocationService _locationService = LocationService();

  LocationPoint? _startPoint;
  LocationPoint? _lastKnownLocation;
  List<LocationPoint> _trackHistory = [];
  bool _isTracking = false;

  LocationPoint? get startPoint => _startPoint;
  LocationPoint? get lastKnownLocation => _lastKnownLocation;
  List<LocationPoint> get trackHistory => List.unmodifiable(_trackHistory);
  bool get isTracking => _isTracking;

  Future<bool> checkAndRequestPermission() async {
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

  Future<LocationPoint?> getCurrentLocation() async {
    final result = await _locationService.getPreciseLocation();

    if (!result.isSuccess) {
      final fallbackAddr = result.needOpenGps ? '请开启手机定位服务' : (result.errorMessage ?? '定位失败，请重试');
      print('[护送定位] getCurrentLocation 定位失败 → address="$fallbackAddr"');
      final point = LocationPoint(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        address: fallbackAddr,
      );
      return point;
    }

    final addr = result.address ?? _formatCoordinateAddress(result);
    print('[护送定位] getCurrentLocation 成功 → address="$addr" (高德地址=${result.address != null ? "是" : "否, 坐标兜底"})');
    final point = LocationPoint(
      latitude: result.latitude!,
      longitude: result.longitude!,
      timestamp: DateTime.now(),
      address: addr,
    );
    _lastKnownLocation = point;
    return point;
  }

  /// Fallback display when reverse geocode fails: "22.543210, 114.058224 (精度 15m)"
  String _formatCoordinateAddress(LocationResult result) {
    final lat = result.latitude!.toStringAsFixed(6);
    final lng = result.longitude!.toStringAsFixed(6);
    if (result.accuracy != null && result.accuracy! > 0) {
      return '$lat, $lng (精度 ${result.accuracy!.round()}m)';
    }
    return '$lat, $lng';
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
