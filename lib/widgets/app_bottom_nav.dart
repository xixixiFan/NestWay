import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 当前选中

  const AppBottomNav({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.sos);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 首页
          GestureDetector(
            onTap: () => _navigate(context, 0),
            child: Icon(
              Icons.map,
              color: currentIndex == 0 ? Colors.black : Colors.grey,
            ),
          ),

          // SOS
          GestureDetector(
            onTap: () => _navigate(context, 1),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFFFE066),
              child: Text('SOS'),
            ),
          ),

          // 我的
          GestureDetector(
            onTap: () => _navigate(context, 2),
            child: Icon(
              Icons.person,
              color: currentIndex == 2 ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}