import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        // 当前已经是预警页？但底部栏索引0对应预警，如果在主页点击预警应该跳转
        // 根据您的设计：0 -> 预警页，1 -> SOS，2 -> 我的
        Navigator.pushNamed(context, AppRoutes.safety);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.sos);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 预警按钮（索引0）
            GestureDetector(
              onTap: () => _navigate(context, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 24,
                    color: currentIndex == 0 ? Colors.black : Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '预警',
                    style: TextStyle(
                      fontSize: 10,
                      color: currentIndex == 0 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // SOS 圆形按钮（索引1）
            GestureDetector(
              onTap: () => _navigate(context, 1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE066),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFE066),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // 我的按钮（索引2）
            GestureDetector(
              onTap: () => _navigate(context, 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 24,
                    color: currentIndex == 2 ? Colors.black : Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '我的',
                    style: TextStyle(
                      fontSize: 10,
                      color: currentIndex == 2 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}