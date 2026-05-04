import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_routes.dart';

class EscortPage extends StatelessWidget {
  const EscortPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('虚拟护送'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 起点输入
              _buildInputCard(
                icon: Icons.my_location,
                hint: '我现在的位置（如：酒店门口）',
              ),

              const SizedBox(height: 16),

              // 终点输入
              _buildInputCard(
                icon: Icons.location_on,
                hint: '目的地（如：地铁站A口）',
              ),

              const SizedBox(height: 16),

              // 时间设置
              _buildInputCard(
                icon: Icons.access_time,
                hint: '预计时间（如：15分钟）',
              ),

              const Spacer(),

              // 开始按钮
              PrimaryButton(
                text: '开始护送',
                size: 160,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.escortProgress);
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 输入卡片组件
  Widget _buildInputCard({
    required IconData icon,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Text(
            hint,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}