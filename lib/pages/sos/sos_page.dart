import 'package:flutter/material.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../services/sos_service.dart';
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

  Future<void> _onSosTriggered() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    try {
      final contacts = _sosService.getEmergencyContacts();
      await _sosService.triggerSos(
        emergencyContacts: contacts,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紧急求助'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _isLoading ? '求助发送中...' : '长按按钮启动求助',
              style: TextStyle(
                fontSize: 16,
                color: _isLoading ? const Color(0xFFFF6B6B) : Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            SosButton(
              size: 160,
              onTriggered: _onSosTriggered,
            ),
            const SizedBox(height: 30),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: const [
                    RiskCard(
                      color: Color(0xFFDFF5E3),
                      title: '轻度不安',
                      desc: '播放模拟通话/视频，制造"有人在联系我"的氛围',
                    ),
                    RiskCard(
                      color: Color(0xFFFFF4D6),
                      title: '中度风险',
                      desc: '实时位置共享给紧急联系人',
                    ),
                    RiskCard(
                      color: Color(0xFFFFE0E0),
                      title: '紧急危险',
                      desc: '尝试拨打报警电话，并发送位置信息',
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}
