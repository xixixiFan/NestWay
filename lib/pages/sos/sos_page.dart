import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/video_player_dialog.dart';
import '../../widgets/call_simulate_dialog.dart';
import '../../services/sos_service.dart';
import '../../services/contacts_provider.dart';
import '../../routes/app_routes.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final SosService _sosService = SosService();
  bool _isLoading = false;
  String? _lastError;
  Timer? _longPressTimer;
  double _pressProgress = 0;
  bool _isLongPressing = false;
  static const _longPressDuration = Duration(seconds: 3);

  Future<void> _onSosTriggered() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final provider = context.read<ContactsProvider>();
      await provider.loadContacts();
      await _sosService.triggerSos(
        emergencyContacts: provider.contacts,
        locationDescription: '当前未知位置',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('求助已发送，紧急联系人已收到通知'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastError = '求助发送失败，请重试';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lastError!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _playAttentionVideo() {
    CallSimulateDialog.show(context);
  }

  void _startLongPress() {
    setState(() {
      _isLongPressing = true;
      _pressProgress = 0;
    });

    final startTime = DateTime.now();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final progress =
          elapsed.inMilliseconds / _longPressDuration.inMilliseconds;

      setState(() {
        _pressProgress = progress.clamp(0.0, 1.0);
      });

      if (progress >= 1.0) {
        timer.cancel();
        _longPressTimer = null;
        _onLongPressComplete();
      }
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    setState(() {
      _isLongPressing = false;
      _pressProgress = 0;
    });
  }

  void _onLongPressComplete() {
    setState(() {
      _isLongPressing = false;
      _pressProgress = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认拨打110'),
          content: const Text('您确定要拨打110报警电话吗？请在拨号盘确认后再正式拨打。'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认拨打'),
              onPressed: () {
                Navigator.of(context).pop();
                _dial110();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _dial110() async {
    try {
      const url = 'tel:110';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        const MethodChannel channel = MethodChannel('com.nestway/phone');
        await channel.invokeMethod('makePhoneCall', {'phoneNumber': '110'});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法拨打电话，请手动拨打110'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> canLaunchUrl(Uri url) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> launchUrl(Uri url) async {
    await launchUrlString(url.toString());
  }

  Future<void> launchUrlString(String url) async {
    const MethodChannel channel = MethodChannel('com.nestway/phone');
    await channel.invokeMethod('openDialer', {'phoneNumber': '110'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 16),
          onPressed: () {
            // 直接返回上一页（超时页面），不清理路由
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'SOS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.sosHistory);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              if (_lastError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _lastError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                    GestureDetector(
                      onLongPressStart: (_) => _startLongPress(),
                      onLongPressEnd: (_) => _cancelLongPress(),
                      onLongPressCancel: _cancelLongPress,
                      child: Stack(
                        children: [
                          RiskCard(
                            color: const Color(0xFFFF6B6B),
                            title: '紧急报警',
                            desc: '长按3秒调起拨号盘 110',
                            icon: Icons.phone,
                          ),
                          if (_isLongPressing)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _pressProgress,
                                        strokeWidth: 4,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${(_pressProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    RiskCard(
                      color: const Color(0xFFFFD93D),
                      title: '共享位置给联系人',
                      desc: '发送位置 + 求助消息',
                      icon: Icons.location_on,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.sendSosMessage);
                      },
                    ),
                    RiskCard(
                      color: const Color(0xFF4A90D9),
                      title: '播放安全视频',
                      desc: '播放视频/模拟通话',
                      icon: Icons.play_circle,
                      onTap: _playAttentionVideo,
                    ),
                  ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
