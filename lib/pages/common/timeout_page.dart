import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/escort_config.dart';
import '../../services/location_service.dart';
import '../../services/sos_service.dart';
import '../../services/escort_service.dart';
import '../../widgets/countdown_ring_painter.dart';
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

class _TimeoutPageState extends State<TimeoutPage>
    with SingleTickerProviderStateMixin {
  final EscortLocationService _locationService = EscortLocationService();
  final SosService _sosService = SosService();
  LocationPoint? _lastLocation;
  bool _isReporting = false;

  late AnimationController _countdownController;
  Timer? _countdownTimer;
  int _countdownSeconds = 105; // 1:45
  bool _countdownExpired = false;
  static const int _totalCountdownSeconds = 105;

  @override
  void initState() {
    super.initState();
    _lastLocation = widget.lastLocation;
    if (_lastLocation == null) {
      _fetchLastLocation();
    }

    _countdownController = AnimationController(
      duration: const Duration(seconds: _totalCountdownSeconds),
      vsync: this,
    );
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_countdownExpired) {
        _onCountdownExpired();
      }
    });
    _countdownController.forward();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownExpired) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          timer.cancel();
        }
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

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
                    '你还好吗？',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  _PulsingDot(),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE066),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            '已超过预计到达时间',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '未收到你的打卡，请确认你的状态',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_lastLocation != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Color(0xFFFFE066),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _lastLocation!.address ?? '已获取最后位置',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '正在获取位置...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),

                          // 倒计时环
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: AnimatedBuilder(
                              animation: _countdownController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: CountdownRingPainter(
                                    progress: 1.0 - _countdownController.value,
                                    isWarning: _countdownSeconds <= 30,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatSeconds(_countdownSeconds),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: _countdownSeconds <= 30
                                            ? const Color(0xFFDC2626)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '倒计时结束后自动通知紧急联系人',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SuccessPage(
                              config: widget.config,
                              lastLocation: _lastLocation,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: const Color(0xFFFFE066),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '我很安全',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isReporting
                          ? null
                          : () async {
                              await _reportTimeout();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/sos',
                                  (route) => false,
                                );
                              }
                            },
                      child: Opacity(
                        opacity: _isReporting ? 0.6 : 1.0,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: Center(
                            child: _isReporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFDC2626),
                                    ),
                                  )
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '需要帮助',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '静默跳转至SOS模式',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
