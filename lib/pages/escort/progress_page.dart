import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../debug/escort_debug.dart';
import '../../models/escort_config.dart';
import '../../services/location_service.dart';
import '../../services/sos_service.dart';
import '../../services/escort_service.dart';
import '../../utils/performance_tracer.dart';
import '../common/timeout_page.dart';
import '../common/success_page.dart';

class ProgressPage extends StatefulWidget {
  final EscortConfig config;

  const ProgressPage({super.key, required this.config});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late int _remainingMinutes;
  late int _remainingSeconds;
  Timer? _timer;
  Timer? _locationTimer;
  bool _isPaused = false;
  final EscortLocationService _locationService = EscortLocationService();
  LocationPoint? _currentLocation;
  int _reportCount = 0;

  @override
  void initState() {
    super.initState();
    print('[ProgressPage] initState() 被调用');
    _remainingMinutes = widget.config.estimatedMinutes;
    _remainingSeconds = 0;
    print('[ProgressPage] 初始倒计时: $_remainingMinutes分$_remainingSeconds秒');
    _startTimer();
    _startLocationTracking();
  }

  @override
  void dispose() {
    print('[ProgressPage] dispose() 被调用');
    _timer?.cancel();
    _locationTimer?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  void _startTimer() {
    print('[ProgressPage] _startTimer() 被调用，当前: $_remainingMinutes分$_remainingSeconds秒');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final skip = EscortDebug.skipTimer();
      setState(() {
        for (int i = 0; i < skip; i++) {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else if (_remainingMinutes > 0) {
            _remainingMinutes--;
            _remainingSeconds = 59;
          } else {
            print('[ProgressPage] 倒计时结束，跳转到 TimeoutPage');
            _timer?.cancel();
            _locationTimer?.cancel();
            _locationService.stopTracking();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TimeoutPage(
                  config: widget.config,
                  lastLocation: _currentLocation,
                ),
              ),
            );
            return;
          }
        }
      });
    });
  }

  void _startLocationTracking() {
    print('[ProgressPage] _startLocationTracking() 被调用');
    _updateCurrentLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCurrentLocation();
    });
  }

  Future<void> _updateCurrentLocation() async {
    print('[ProgressPage] _updateCurrentLocation() 被调用');
    final t = PerformanceTracer.instance;
    final location = await t.traceAuto('progress_update_location',
        () => _locationService.recordCurrentPosition());
    if (location != null && mounted) {
      print('[ProgressPage] 更新位置: ${location.address}');
      setState(() {
        _currentLocation = location;
      });
      _reportCount++;
      print('[ProgressPage] 已上报位置: $_reportCount次');
      await t.traceAuto('report_location_to_server',
          () => _locationService.reportLocationToServer(
                escortId: widget.config.escortId,
                lat: location.latitude,
                lng: location.longitude,
                address: location.address,
                dbTaskId: EscortService().currentTaskId,
              ));
    }
  }

  /// Haversine 公式计算两点间距离（单位：公里）
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180.0;

  Future<void> _onCheckIn(BuildContext context) async {
    print('[ProgressPage] 点击安全打卡');
    await PerformanceTracer.instance.trace('progress_checkin_tap', () async {
    // 暂停定时器，防止等待定位期间倒计时继续走
    _timer?.cancel();
    _locationTimer?.cancel();
    final wasPaused = _isPaused;
    _isPaused = true;

    final destLat = widget.config.destinationLat;
    final destLng = widget.config.destinationLng;

    // 获取当前位置
    final now = await _locationService.getCurrentLocation();
    if (!mounted) return;

    // 无目的地坐标或无法定位 → 直接走原流程
    if (destLat == null || destLng == null ||
        now == null || now.latitude == 0) {
      _goToSuccess(now);
      return;
    }

    final dist = _distanceKm(now.latitude, now.longitude, destLat, destLng);

    if (dist <= 0.5) {
      // ≤500m → 你已安全到达
      _goToSuccess(now);
    } else {
      // >500m → 询问确认（用户取消时恢复定时器）
      _showArrivalConfirm(context, now, dist, wasPaused);
    }
    }, input: {
      'destination': widget.config.destination,
      'dest_lat': widget.config.destinationLat,
      'dest_lng': widget.config.destinationLng,
    });
  }

  void _goToSuccess(LocationPoint? location) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessPage(
          config: widget.config,
          lastLocation: location,
        ),
      ),
    );
  }

  void _showArrivalConfirm(
      BuildContext context, LocationPoint location, double distKm, bool wasPaused) {
    final distText = distKm < 1.0
        ? '${(distKm * 1000).round()} 米'
        : '${distKm.toStringAsFixed(1)} 公里';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F0FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // 距离图标
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 40,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '你似乎还没到达目的地',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '当前距离目的地约 $distText',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '确认已经安全到达了吗？',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 28),

            // 确认安全按钮
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _goToSuccess(location);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Text(
                      '确认已安全到达',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 继续护送按钮 — 恢复定时器
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  if (!wasPaused) {
                    setState(() => _isPaused = false);
                    _startTimer();
                    _startLocationTracking();
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Text(
                      '继续护送',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String phone) {
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    print('[ProgressPage] build() 被调用，当前: $_remainingMinutes分$_remainingSeconds秒');
    return EscortDebugFloatingButton(
      actions: [
        DebugAction(
          label: '直接超时 → TimeoutPage',
          icon: Icons.timer_off,
          color: Colors.orange,
          onTap: () {
            _timer?.cancel();
            _locationTimer?.cancel();
            _locationService.stopTracking();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TimeoutPage(
                  config: widget.config,
                  lastLocation: _currentLocation,
                ),
              ),
            );
          },
        ),
        DebugAction(
          label: '打卡成功 → SuccessPage',
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: () => _goToSuccess(_currentLocation),
        ),
        DebugAction(
          label: '距离外弹窗 → 确认到达',
          icon: Icons.location_on,
          color: Colors.orange,
          onTap: () {
            final loc = _currentLocation;
            final destLat = widget.config.destinationLat;
            final destLng = widget.config.destinationLng;
            final dist = (loc != null && destLat != null && destLng != null)
                ? _distanceKm(loc.latitude, loc.longitude, destLat, destLng)
                : 1.2;
            _showArrivalConfirm(
              context,
              loc ?? LocationPoint(
                latitude: widget.config.startPoint.latitude,
                longitude: widget.config.startPoint.longitude,
                timestamp: DateTime.now(),
              ),
              dist,
              _isPaused,
            );
          },
        ),
      ],
      child: Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 顶部导航栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black54),
                    ),
                  ),
                  const Text(
                    '护送进行中',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 内容区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // 路径卡片
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左侧图标列：空心圆 + 虚线 + 黄色定位
                          Column(
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black87,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              // 虚线
                              SizedBox(
                                height: 48,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const dashHeight = 4.0;
                                    const dashSpace = 3.0;
                                    final count = (constraints.maxHeight / (dashHeight + dashSpace)).floor();
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(count, (_) => Padding(
                                        padding: const EdgeInsets.only(bottom: dashSpace),
                                        child: Container(
                                          width: 2,
                                          height: dashHeight,
                                          color: Colors.grey[400],
                                        ),
                                      )),
                                    );
                                  },
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 22,
                                color: Color(0xFFFFE066),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // 右侧文字列
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 出发地
                                const Text(
                                  '出发地',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '我的当前位置',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // 目的地
                                const Text(
                                  '目的地',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.config.destination,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 倒计时卡片
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '距离预计结束还有',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_remainingMinutes.toString().padLeft(2, '0')}'
                            '分'
                            '${_remainingSeconds.toString().padLeft(2, '0')}'
                            '秒',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.gps_fixed,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '已上报 ${_reportCount} 次',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 超时警告条
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '超时未打卡将自动通知紧急联系人',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 紧急联系人标题
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '紧急联系人',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ),

                  // 紧急联系人卡片
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFFE566),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.teal[300],
                              child: ClipOval(
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop',
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 28,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.config.contacts.isNotEmpty
                                      ? widget.config.contacts[0]['name'] as String? ?? '张美美'
                                      : '张美美',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.config.contacts.isNotEmpty
                                      ? _formatPhone(widget.config.contacts[0]['phone'] as String? ?? '13888888888')
                                      : '138 **** 5678',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                final phone = widget.config.contacts.isNotEmpty
                                    ? widget.config.contacts[0]['phone'] as String? ?? ''
                                    : '';
                                if (phone.isNotEmpty) {
                                  SosService().makePhoneCall(phone);
                                }
                              },
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 底部
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    print('[ProgressPage] 点击暂停/继续按钮，当前: $_isPaused');
                    setState(() {
                      _isPaused = !_isPaused;
                      if (_isPaused) {
                        _timer?.cancel();
                        _locationTimer?.cancel();
                      } else {
                        _startTimer();
                        _startLocationTracking();
                      }
                    });
                  },
                  child: Text(
                    _isPaused ? '继续护送' : '暂停护送',
                    style: TextStyle(
                      color: _isPaused ? const Color(0xFF10B981) : Colors.black38,
                      fontSize: 14,
                      fontWeight: _isPaused ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => _onCheckIn(context),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE066),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFE066).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '安全打卡',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  // 通用卡片组件
  static Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
