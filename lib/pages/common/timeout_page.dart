import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/escort_config.dart';
import '../../services/location_service.dart';
import '../../services/sos_service.dart';
import '../../services/escort_service.dart';
import '../../widgets/countdown_ring_painter.dart';
import '../../debug/escort_debug.dart';
import '../../widgets/countdown_ended_dialog.dart';
import 'success_page.dart';

class TimeoutPage extends StatefulWidget {
  final EscortConfig config;
  final LocationPoint? lastLocation;

  const TimeoutPage({
    super.key,
    required this.config,
    this.lastLocation,
  });

  @override
  State<TimeoutPage> createState() => _TimeoutPageState();
}

class _TimeoutPageState extends State<TimeoutPage> {
  final EscortLocationService _locationService = EscortLocationService();
  final SosService _sosService = SosService();
  LocationPoint? _lastLocation;
  bool _isReporting = false;

  Timer? _countdownTimer;
  int _countdownSeconds = 90;
  bool _countdownExpired = false;
  static const int _totalCountdownSeconds = 90;

  @override
  void initState() {
    super.initState();
    _lastLocation = widget.lastLocation;
    if (_lastLocation == null) {
      _fetchLastLocation();
    }
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownExpired) {
        timer.cancel();
        return;
      }
      final skip = EscortDebug.skipTimer();
      bool expired = false;
      setState(() {
        for (int i = 0; i < skip; i++) {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          }
          if (_countdownSeconds <= 0) {
            expired = true;
            break;
          }
        }
      });
      if (expired) {
        timer.cancel();
        _onCountdownExpired();
      }
    });
  }

  Future<void> _fetchLastLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _lastLocation = location;
      });
    }
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onCountdownExpired() async {
    _countdownExpired = true;
    _countdownTimer?.cancel();

    final contacts = widget.config.contacts;
    final phones = contacts
        .map((c) => c['phone'] as String?)
        .whereType<String>()
        .toList();

    if (phones.isNotEmpty) {
      final name = await _sosService.getUserDisplayName();
      final location = _lastLocation ?? await _locationService.getCurrentLocation();

      await _sosService.sendSosSms(
        phones: phones,
        name: name,
        location: location?.address ?? '未知位置',
        coords: location != null
            ? '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}'
            : null,
      );

      await _sosService.reportSosEvent(
        type: 'escort_timeout',
        locationDescription: location?.address,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
    }

    if (_lastLocation != null) {
      final contactNames = contacts.map((c) => c['name'] as String).toList();
      await _locationService.reportTimeoutAlert(
        escortId: widget.config.escortId,
        lastLocation: _lastLocation!,
        emergencyContacts: contactNames,
      );
    }

    // 写入数据库：护送超时
    await EscortService().timeoutEscort(lastLocation: _lastLocation);

    if (mounted) {
      CountdownEndedDialog.show(
        context,
        onSendExplanation: () => _sendSafetyExplanation(phones),
        onClose: () {},
      );
    }
  }

  Future<void> _sendSafetyExplanation(List<String> phones) async {
    if (phones.isEmpty) return;
    final name = await _sosService.getUserDisplayName();
    await _sosService.sendSosSms(
      phones: phones,
      name: name,
      location: '用户已确认安全，仅为超时未及时打卡，无需担心。',
      coords: null,
    );
  }

  Future<void> _reportTimeout() async {
    if (_isReporting) return;
    setState(() => _isReporting = true);

    if (_lastLocation != null) {
      final contacts = widget.config.contacts.map((c) => c['name'] as String).toList();
      await _locationService.reportTimeoutAlert(
        escortId: widget.config.escortId,
        lastLocation: _lastLocation!,
        emergencyContacts: contacts,
      );
    }

    if (mounted) {
      setState(() => _isReporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EscortDebugFloatingButton(
      actions: [
        DebugAction(label: '我很安全 → SuccessPage', icon: Icons.check_circle, color: Colors.green,
          onTap: () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => SuccessPage(config: widget.config, lastLocation: _lastLocation)),
                (route) => false);
            }
          }),
        DebugAction(label: '需要帮助 → SOS 页', icon: Icons.warning, color: Colors.red,
          onTap: () {
            _countdownTimer?.cancel();
            EscortService().markAsSos(lastLocation: _lastLocation);
            if (mounted) Navigator.pushReplacementNamed(context, '/sos');
          }),
        DebugAction(label: '立即触发倒计时到期', icon: Icons.timer_off, color: Colors.orange,
          onTap: () => _onCountdownExpired()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F0FF),
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black54),
                    ),
                    const Spacer(),
                    const Text('你还好吗？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const Spacer(),
                    _PulsingDot(),
                  ],
                ),
              ),

              const Spacer(),

              // 中央白色卡片
              Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      // 黄色感叹号图标
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE066),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high, size: 32, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),

                      const Text('已超过预计到达时间', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('未收到你的打卡，请确认你的状态',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.center),

                      const SizedBox(height: 28),

                      // 倒计时环
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: CountdownRingPainter(
                            progress: 1.0 - (_countdownSeconds / _totalCountdownSeconds),
                            isWarning: _countdownSeconds <= 30,
                          ),
                          child: Center(
                            child: Text(
                              _formatSeconds(_countdownSeconds),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _countdownSeconds <= 30 ? const Color(0xFFDC2626) : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('倒计时结束后将通知紧急联系人',
                          style: TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // 底部位置信息
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _locationRow(Icons.location_on, '当前定位：${_lastLocation?.address ?? '获取中...'}'),
                    const SizedBox(height: 8),
                    _locationRow(Icons.flag, '目的地：${widget.config.destination}'),
                  ],
                ),
              ),

              const Spacer(),

              // 并排按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(context,
                              MaterialPageRoute(builder: (_) => SuccessPage(config: widget.config, lastLocation: _lastLocation)),
                              (route) => false);
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE066),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text('我很安全', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isReporting ? null : () async {
                          setState(() => _isReporting = true);
                          await EscortService().markAsSos(lastLocation: _lastLocation);
                          await _reportTimeout();
                          _countdownTimer?.cancel();
                          if (mounted) {
                            setState(() => _isReporting = false);
                            Navigator.pushReplacementNamed(context, '/sos');
                          }
                        },
                        child: Opacity(
                          opacity: _isReporting ? 0.6 : 1.0,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: _isReporting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)))
                                  : const Text('需要帮助', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text('加密护航链路已断开', style: TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: icon == Icons.location_on ? const Color(0xFFFFE066) : Colors.black38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE066).withOpacity(_animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE066).withOpacity(0.6 * _animation.value),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
