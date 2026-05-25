import 'dart:ui';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../services/location_service.dart';
import '../../services/escort_service.dart';
import '../../models/escort_config.dart';
import '../../pages/escort/progress_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _cityName = '定位中';
  bool _isLocating = true;
  bool _isCheckingEscort = false;

  @override
  void initState() {
    super.initState();
    _fetchCity();
  }

  Future<void> _fetchCity() async {
    final result = await LocationService().getPreciseLocation();
    if (mounted) {
      setState(() {
        _isLocating = false;
        _cityName = result.city ??
            result.address?.split('·').first.trim() ??
            '未知城市';
      });
    }
  }

  /// 点击护送按钮：先查未完成护送，有则恢复，无则新建
  Future<void> _onEscortTap() async {
    if (_isCheckingEscort) return;
    setState(() => _isCheckingEscort = true);

    try {
      final active = await EscortService().getActiveEscort();

      if (!mounted) return;

      if (active != null) {
        // 恢复未完成的护送
        final contacts = (active['emergency_contacts'] as List<dynamic>?)
                ?.map((e) => {'name': e as String, 'phone': ''})
                .toList() ??
            [];

        final config = EscortConfig(
          escortId: active['escort_id'] as String? ?? '',
          destination: active['destination'] as String? ?? '未指定目的地',
          estimatedMinutes: active['estimated_minutes'] as int? ?? 30,
          startPoint: LocationPoint(
            latitude: (active['start_latitude'] as num?)?.toDouble() ?? 0,
            longitude: (active['start_longitude'] as num?)?.toDouble() ?? 0,
            timestamp: DateTime.tryParse(active['started_at'] as String? ?? '') ?? DateTime.now(),
            address: active['start_address'] as String?,
          ),
          contacts: contacts,
        );

        // 弹出提示，让用户选择恢复还是新建
        final resume = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('发现未完成的护送'),
            content: Text('目的地：${config.destination}\n\n是否继续这次护送？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('新建护送', style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE066),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('继续护送'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (resume == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProgressPage(config: config)),
          );
          return;
        }
      }

      // 无未完成护送，或用户选择新建
      Navigator.pushNamed(context, AppRoutes.escort);
    } finally {
      if (mounted) setState(() => _isCheckingEscort = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Stack(
          children: [
            // 抽象装饰层 - 模糊光晕
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE066).withOpacity(0.15),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 品牌头部
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Nestway',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        // 城市安全状态
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 5,
                                    backgroundColor: _isLocating
                                        ? Colors.grey
                                        : const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_cityName · 当前安全',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                  // 大守护按钮
                  Center(
                    child: GestureDetector(
                      onTap: _onEscortTap,
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE066),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE066).withOpacity(0.4),
                              blurRadius: 60,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isCheckingEscort)
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Colors.black54,
                                  strokeWidth: 3,
                                ),
                              )
                            else
                              const Icon(Icons.shield, size: 72, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 标题文字
                  const Center(
                    child: Text(
                      '虚拟护送',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      '设置目的地，全程守护你',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 底部导航栏
                  const AppBottomNav(currentIndex: 0),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
