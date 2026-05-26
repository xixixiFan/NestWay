import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '安全预警',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Center(child: Text('安全页面')),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(currentIndex: 0),
          ),
        ],
      ),
    );
  }
}