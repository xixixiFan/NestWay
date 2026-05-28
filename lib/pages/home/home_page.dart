import 'dart:ui';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _cityName = '定位中';
  bool _isLocating = true;

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final buttonSize = screenWidth * 0.56;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            // 品牌头部
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                isSmallScreen ? 16 : 24,
                screenWidth * 0.06,
                0,
              ),
              child: Row(
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

            // 弹性空间 → 按钮区垂直居中
            const Spacer(),

            // 虚拟护送按钮 + 光晕
            Center(
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 模糊光晕
                    Container(
                      width: buttonSize * 1.8,
                      height: buttonSize * 1.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFE066).withOpacity(0.15),
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                    // 按钮
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.escort);
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE066),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE066).withOpacity(0.5),
                              blurRadius: buttonSize * 0.25,
                              offset: Offset(0, buttonSize * 0.06),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield, size: 48, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            const Center(
              child: Text(
                '虚拟护送',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            const Center(
              child: Text(
                '设置目的地，全程守护你',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),

            // 弹性空间 → 按钮区垂直居中
            const Spacer(),

            // 底部导航栏 — 始终固定
            const AppBottomNav(currentIndex: -1),
          ],
        ),
      ),
    );
  }
}
