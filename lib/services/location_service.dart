import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/amap_config.dart';
import '../utils/performance_tracer.dart';
import 'supabase_service.dart';

/// Unified location result returned by [LocationService].
class LocationResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? address;
  final String? city;           // 城市名，如"深圳市"
  final String? errorMessage;
  final bool needOpenGps;

  LocationResult({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
    this.city,
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

  static const _timeLimit = Duration(seconds: 20);
  static const _sampleCount = 2;
  static const _graceAfterFirst = Duration(milliseconds: 3000);
  static const _goodAccuracyMeters = 20;
  static const _amapApiKey = amapApiKey;
  static const _httpTimeout = Duration(seconds: 5);

  /// Main entry: get precise location with multi-sampling.
  /// Returns [LocationResult] with address from reverse geocoding.
  Future<LocationResult> getPreciseLocation() async {
    final t = PerformanceTracer.instance;
    print('[定位] === getPreciseLocation 开始 ===');

    // 1. Check if system GPS is enabled
    final gpsEnabled = await t.traceAuto('check_gps_enabled',
        () => Geolocator.isLocationServiceEnabled(),
        thread: 'platform');
    print('[定位] GPS 服务状态: $gpsEnabled');
    if (!gpsEnabled) {
      print('[定位] ❌ GPS 未开启，返回 needOpenGps');
      return LocationResult(
        errorMessage: '请开启手机定位服务',
        needOpenGps: true,
      );
    }

    // 2. Check permission
    LocationPermission permission = await t.traceAuto('check_permission',
        () => Geolocator.checkPermission(),
        thread: 'platform');
    print('[定位] 定位权限: $permission');
    if (permission == LocationPermission.denied) {
      permission = await t.traceAuto('request_permission',
          () => Geolocator.requestPermission(),
          thread: 'platform');
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

    // 3. Quick cached position (instant, avoids cold-start waiting)
    Position? cachedPosition;
    try {
      cachedPosition = await t.traceAuto('get_last_known',
          () => Geolocator.getLastKnownPosition(),
          thread: 'platform');
      print('[定位] 缓存位置: ${cachedPosition != null ? "lat=${cachedPosition.latitude.toStringAsFixed(6)} lng=${cachedPosition.longitude.toStringAsFixed(6)}" : "无"}');
    } catch (e) {
      print('[定位] 获取缓存位置异常: $e');
    }

    // 4. Multi-sampling for fresh GPS fix
    final bestPosition = await t.traceAuto('gps_multi_sample',
        () => _samplePosition(t),
        thread: 'platform');

    // 5. Fallback chain: fresh sample → cached → error
    final Position? finalPosition = bestPosition ?? cachedPosition;
    if (finalPosition == null) {
      return LocationResult(errorMessage: '无法获取当前位置，请确认定位服务已开启且在室外空旷处重试');
    }

    final bool isCached = bestPosition == null && cachedPosition != null;
    if (isCached) {
      print('[定位] ⚠️ 使用缓存位置（GPS 采样未返回新鲜数据）');
    }

    // 6. Reverse geocode
    print('[定位] 最终坐标: lat=${finalPosition.latitude.toStringAsFixed(6)} lng=${finalPosition.longitude.toStringAsFixed(6)}');
    final geoResult = await t.traceAuto('reverse_geocode',
        () => _reverseGeocode(finalPosition.latitude, finalPosition.longitude),
        thread: 'http');
    print('[定位] 逆地理编码结果: address=${geoResult['address']} city=${geoResult['city']}');

    final result = LocationResult(
      latitude: finalPosition.latitude,
      longitude: finalPosition.longitude,
      accuracy: finalPosition.accuracy,
      address: geoResult['address'],
      city: geoResult['city'],
    );
    print('[定位] === getPreciseLocation 返回: lat=${result.latitude?.toStringAsFixed(6)} lng=${result.longitude?.toStringAsFixed(6)} accuracy=${result.accuracy}m address="${result.address ?? "(null)"}" city="${result.city ?? "(null)"}" ===');
    return result;
  }

  Future<Position?> _samplePosition(PerformanceTracer t) async {
    print('[定位] 开始采样 (目标 $_sampleCount 个点, 首点宽限 ${_graceAfterFirst.inMilliseconds}ms, 硬超时 ${_timeLimit.inSeconds}s)...');
    final samples = <Position>[];
    StreamSubscription<Position>? subscription;
    Timer? graceTimer;
    final completer = Completer<void>();

    try {
      subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeLimit,
        ),
      ).listen(
        (position) {
          samples.add(position);
          print('[定位]   收到第 ${samples.length} 个采样: lat=${position.latitude.toStringAsFixed(6)} lng=${position.longitude.toStringAsFixed(6)} accuracy=${position.accuracy}m');

          if (samples.length >= _sampleCount) {
            graceTimer?.cancel();
            if (!completer.isCompleted) completer.complete();
          } else if (samples.length == 1) {
            if (position.accuracy <= _goodAccuracyMeters) {
              print('[定位] 首点精度已达标 (${position.accuracy}m ≤ ${_goodAccuracyMeters}m)，跳过后续采样');
              graceTimer?.cancel();
              if (!completer.isCompleted) completer.complete();
            } else {
              graceTimer?.cancel();
              graceTimer = Timer(_graceAfterFirst, () {
                print('[定位] 首点宽限期到 (${_graceAfterFirst.inMilliseconds}ms)，精度 ${position.accuracy}m > ${_goodAccuracyMeters}m，已收集 ${samples.length} 个点');
                if (!completer.isCompleted) completer.complete();
              });
            }
          }
        },
        onError: (e) {
          print('[定位] 流错误: $e');
          graceTimer?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          print('[定位] 流结束, 共收到 ${samples.length} 个采样');
          graceTimer?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );

      try {
        await completer.future.timeout(_timeLimit);
      } on TimeoutException {
        print('[定位] 采样硬超时 (${_timeLimit.inSeconds}s), 已收集 ${samples.length} 个点');
      }
    } catch (e) {
      print('[定位] 采样异常: $e');
    } finally {
      graceTimer?.cancel();
      await subscription?.cancel();
    }

    if (samples.isNotEmpty) {
      samples.sort((a, b) => (a.accuracy).compareTo(b.accuracy));
      final best = samples.first;
      print('[定位] 从 ${samples.length} 个采样中取最优: accuracy=${best.accuracy}m');
      return best;
    }

    print('[定位] 无采样, 回退到单次 getCurrentPosition...');
    try {
      final fallback = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeLimit * 2,
        ),
      );
      print('[定位] 单次定位结果: lat=${fallback.latitude.toStringAsFixed(6)} lng=${fallback.longitude.toStringAsFixed(6)} accuracy=${fallback.accuracy}m');
      return fallback;
    } catch (e) {
      print('[定位] ❌ 单次定位也失败: $e');
      return null;
    }
  }

  Future<Map<String, String?>> _reverseGeocode(double lat, double lng) async {
    print('[逆地理] 请求高德API: lat=$lat lng=$lng');
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo?key=$_amapApiKey&location=$lng,$lat&extensions=all',
      );
      print('[逆地理] URL: $url');
      
      // 添加超时设置
      final client = http.Client();
      try {
        final response = await client.get(url).timeout(
          _httpTimeout,
          onTimeout: () {
            print('[逆地理] ⚠️ HTTP 请求超时 (${_httpTimeout.inSeconds}s)');
            throw TimeoutException('请求超时');
          },
        );
        
        print('[逆地理] HTTP ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('[逆地理] API status=${data['status']} info=${data['info']}');
          
          if (data['status'] == '1' && data['regeocode'] != null) {
            final regeocode = data['regeocode'] as Map<String, dynamic>?;
            String? shortAddress;
            String? city;

            if (regeocode != null) {
              final addressComponent = regeocode['addressComponent'] as Map<String, dynamic>?;

              if (addressComponent != null) {
                // 高德API的city字段——内地为字符串（如"深圳市"），港澳台为空数组[]
                final rawCity = addressComponent['city'];
                city = (rawCity is String && rawCity.isNotEmpty
                    ? rawCity.replaceAll('市', '')
                    : null)
                    // 港澳台等city为空时，降级用province
                    ?? (addressComponent['province'] is String
                        ? (addressComponent['province'] as String).replaceAll('市', '')
                        : null);

                final district = addressComponent['district'] as String? ?? '';
                final township = addressComponent['township'] as String? ?? '';
                final street = addressComponent['streetNumber']?['street'] as String? ?? '';

                if (district.isNotEmpty) {
                  shortAddress = district;
                  if (township.isNotEmpty && township != district) {
                    shortAddress = '$shortAddress$township';
                  }
                  if (street.isNotEmpty) {
                    shortAddress = '$shortAddress$street';
                    final number = addressComponent['streetNumber']?['number'] as String? ?? '';
                    if (number.isNotEmpty) {
                      shortAddress = '$shortAddress$number';
                    }
                  }
                }
              }

              if (shortAddress == null || shortAddress.isEmpty) {
                final formatted = regeocode['formatted_address'] as String?;
                if (formatted != null) {
                  shortAddress = _shortenAddress(formatted);
                }
              }
            }

            print('[逆地理] ✅ 解析成功: 简洁地址=$shortAddress, 城市=$city');
            return {'address': shortAddress, 'city': city};
          } else {
            print('[逆地理] ❌ API返回错误: status=${data['status']} info=${data['info']}');
            return await _coordinateFallback(lat, lng);
          }
        } else {
          print('[逆地理] ❌ HTTP错误: statusCode=${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('[逆地理] ❌ 异常: $e (${e.runtimeType})');
      return await _coordinateFallback(lat, lng);
    }

    return await _coordinateFallback(lat, lng);
  }

  /// 高德 API 失败时的兜底 — 返回坐标
  Future<Map<String, String?>> _coordinateFallback(double lat, double lng) async {
    print('[兜底] 高德 API 不可用，返回坐标: lat=$lat lng=$lng');
    return {'address': '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}', 'city': null};
  }

  /// 截取简洁地址：去掉省市区前缀，保留街道级别信息
  String _shortenAddress(String fullAddress) {
    // 常见前缀模式：省/市/区/县
    final patterns = [
      RegExp(r'^[^市]+市'),  // 匹配到"xx市"
      RegExp(r'^[^区]+区'),  // 匹配到"xx区"
      RegExp(r'^[^县]+县'),  // 匹配到"xx县"
    ];
    
    String result = fullAddress;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(result);
      if (match != null && match.end < result.length) {
        result = result.substring(match.end);
      }
    }
    
    // 如果结果太长，再截取前20个字符
    if (result.length > 20) {
      result = '${result.substring(0, 20)}...';
    }
    
    return result.isEmpty ? fullAddress : result;
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
    final t = PerformanceTracer.instance;
    final result = await t.traceAuto('EscortLocationService.getCurrentLocation',
        () => _locationService.getPreciseLocation());

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
    print('[护送定位] getCurrentLocation 成功 → address="$addr"');
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
    final t = PerformanceTracer.instance;
    _isTracking = true;
    _trackHistory.clear();
    final location = await t.traceAuto('EscortLocationService.startTracking',
        () => getCurrentLocation());
    if (location != null) {
      _startPoint = location;
      _trackHistory.add(location);
    }
    return location;
  }

  Future<LocationPoint?> recordCurrentPosition() async {
    if (!_isTracking) return null;
    final location = await PerformanceTracer.instance
        .traceAuto('EscortLocationService.recordCurrentPosition',
            () => getCurrentLocation());
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
    int? dbTaskId,
  }) async {
    if (dbTaskId == null) {
      print('[位置上报] ⚠️ 无 DB 任务 ID，跳过');
      return true;
    }
    try {
      await SupabaseService.instance
          .from('escort_tasks')
          .update({
            'last_location_lat': lat,
            'last_location_lng': lng,
          })
          .eq('id', dbTaskId);
      print('[位置上报] ✅ 已更新 DB: taskId=$dbTaskId, lat=$lat, lng=$lng');
      return true;
    } catch (e) {
      print('[位置上报] ❌ 失败: $e');
      return false;
    }
  }

  Future<bool> reportEscortStart({
    required String escortId,
    required String destination,
    required int estimatedMinutes,
    required LocationPoint startPoint,
  }) async {
    // 护送开始的 DB 写入已在 EscortService.startEscort 中完成。
    print('🚗 护送开始: escortId=$escortId, destination=$destination, estimatedMinutes=$estimatedMinutes');
    print('   起点: ${startPoint.address}');
    return true;
  }

  Future<bool> reportEscortEnd({
    required String escortId,
    required String endType,
    LocationPoint? endPoint,
  }) async {
    // 护送结束的 DB 写入已在 EscortService.completeEscort 中完成。
    print('🏁 护送结束: escortId=$escortId, endType=$endType');
    if (endPoint != null) {
      print('   终点: ${endPoint.address}');
    }
    print('   轨迹点数量: ${_trackHistory.length}');
    return true;
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
