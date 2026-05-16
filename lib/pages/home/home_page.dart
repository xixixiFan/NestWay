import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Logo + 城市状态
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NestWay',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xFF10B981),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '深圳 · 当前安全',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 中间大的虚拟护送按钮
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.escort);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE066),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFE066).withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield,
                      size: 64,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '虚拟护送',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '设置目的地，全程守护你',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const Spacer(flex: 2),

            // 底部导航栏
            const AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}