import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  static const _timeLimit = Duration(seconds: 10);
  static const _sampleCount = 2;
  static const _amapApiKey = '89ff90f769765ecd5f68e2cb48e283cb';
  static const _httpTimeout = Duration(seconds: 8);

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
    final geoResult = await _reverseGeocode(
      bestPosition.latitude,
      bestPosition.longitude,
    );
    print('[定位] 逆地理编码结果: address=${geoResult['address']} city=${geoResult['city']}');

    final result = LocationResult(
      latitude: bestPosition.latitude,
      longitude: bestPosition.longitude,
      accuracy: bestPosition.accuracy,
      address: geoResult['address'],
      city: geoResult['city'],
    );
    print('[定位] === getPreciseLocation 返回: lat=${result.latitude?.toStringAsFixed(6)} lng=${result.longitude?.toStringAsFixed(6)} accuracy=${result.accuracy}m address="${result.address ?? "(null)"}" city="${result.city ?? "(null)"}" ===');
    return result;
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
                // 提取城市名（去掉"市"字更简洁）
                // 高德API的city字段可能是String或空List(无城市时)
                final rawCity = addressComponent['city'];
                city = (rawCity is String ? rawCity : null)?.replaceAll('市', '');

                final district = addressComponent['district'] as String? ?? '';
                final township = addressComponent['township'] as String? ?? '';
                final street = addressComponent['streetNumber']?['street'] as String? ?? '';

                if (district.isNotEmpty) {
                  shortAddress = district;
                  if (township.isNotEmpty && township != district) {
                    shortAddress = '$district$township';
                  } else if (street.isNotEmpty) {
                    shortAddress = '$district$street';
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
            // API Key 无效或超限，备用方案
            final fallback = _generateFallbackAddress(lat, lng);
            print('[逆地理] 🔄 使用备用地址: $fallback');
            return {'address': fallback, 'city': null};
          }
        } else {
          print('[逆地理] ❌ HTTP错误: statusCode=${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('[逆地理] ❌ 异常: $e (${e.runtimeType})');
      // 网络异常时使用备用地址
      final fallback = _generateFallbackAddress(lat, lng);
      print('[逆地理] 🔄 使用备用地址: $fallback');
      return {'address': fallback, 'city': null};
    }
    
    // 最终备用
    final fallback = _generateFallbackAddress(lat, lng);
    print('[逆地理] 🔄 最终备用地址: $fallback');
    return {'address': fallback, 'city': null};
  }

  /// 根据经纬度生成简化的地址描述（基于常见城市的大致范围）
  String _generateFallbackAddress(double lat, double lng) {
    // 根据经纬度判断大致区域（这是一个简化的备用方案）
    // 纬度范围: 3° ~ 54° (中国)
    // 经度范围: 73° ~ 135° (中国)
    
    // 尝试判断城市
    String city = '';
    String district = '';
    
    // 广东省大致范围
    if (lat >= 20.0 && lat <= 25.5 && lng >= 109.0 && lng <= 117.5) {
      if (lat >= 22.4 && lat <= 22.9 && lng >= 113.7 && lng <= 114.5) {
        city = '深圳市';
        if (lat >= 22.4 && lat <= 22.6) district = '南山区';
        else if (lat >= 22.6 && lat <= 22.8) district = '福田区';
        else district = '龙岗区';
      } else if (lat >= 22.9 && lat <= 23.5 && lng >= 112.8 && lng <= 113.5) {
        city = '广州市';
        if (lng >= 113.2 && lng <= 113.5) district = '天河区';
        else if (lng >= 113.0 && lng <= 113.2) district = '越秀区';
        else district = '白云区';
      } else {
        city = '广东省';
        district = '其他区域';
      }
    }
    // 北京市大致范围
    else if (lat >= 39.4 && lat <= 41.0 && lng >= 115.4 && lng <= 117.5) {
      city = '北京市';
      if (lng >= 116.2 && lng <= 116.5) district = '朝阳区';
      else if (lng >= 116.1 && lng <= 116.2) district = '东城区';
      else district = '其他区';
    }
    // 上海市大致范围
    else if (lat >= 30.7 && lat <= 31.5 && lng >= 120.8 && lng <= 122.0) {
      city = '上海市';
      if (lng >= 121.4 && lng <= 121.6) district = '黄浦区';
      else if (lng >= 121.2 && lng <= 121.4) district = '静安区';
      else district = '浦东新区';
    }
    // 默认
    else {
      // 返回经纬度（格式化为更易读的形式）
      final latStr = lat.toStringAsFixed(4);
      final lngStr = lng.toStringAsFixed(4);
      return '$latStr, $lngStr';
    }
    
    // 如果能判断出城市，返回城市+区域
    if (city.isNotEmpty && district.isNotEmpty) {
      return '$city$district';
    } else if (city.isNotEmpty) {
      return city;
    }
    
    // 最后兜底：返回经纬度
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
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
