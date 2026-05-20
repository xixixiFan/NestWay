import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/escort_config.dart';
import '../../services/location_service.dart';
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
    _remainingMinutes = widget.config.estimatedMinutes;
    _remainingSeconds = 0;
    _startTimer();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else if (_remainingMinutes > 0) {
          _remainingMinutes--;
          _remainingSeconds = 59;
        } else {
          _timer?.cancel();
          _locationTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TimeoutPage(
                config: widget.config,
                lastLocation: _currentLocation,
              ),
            ),
          );
        }
      });
    });
  }

  void _startLocationTracking() {
    _updateCurrentLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCurrentLocation();
    });
  }

  Future<void> _updateCurrentLocation() async {
    final location = await _locationService.recordCurrentPosition();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
      _reportCount++;
      await _locationService.reportLocationToServer(
        escortId: widget.config.escortId,
        lat: location.latitude,
        lng: location.longitude,
        address: location.address,
      );
    }
  }

  String _formatPhone(String phone) {
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 顶部导航栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '护送进行中',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.black87,
                              ),
                              Container(
                                height: 32,
                                width: 2,
                                color: Colors.grey[300],
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFFFFE066),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (_currentLocation != null)
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '我的当前位置',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _currentLocation != null
                                    ? Text(
                                        _currentLocation!.address ?? '已获取位置',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : const Text(
                                        '正在获取位置...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.config.destination,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
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
                              onPressed: () {},
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuccessPage(
                            config: widget.config,
                            lastLocation: _currentLocation,
                          ),
                        ),
                      );
                    },
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
