import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Logo + 城市
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'NestWay',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Text('深圳 · 当前安全'),
                ),
              ],
            ),

            const Spacer(),

            // 中间大按钮
            PrimaryButton(
              text: '虚拟护送',
              size: 180,
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.escort);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              '设置目的地，全程守护你',
              style: TextStyle(color: Colors.black54),
            ),

            const Spacer(),

            const AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}