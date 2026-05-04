import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/app_bottom_nav.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紧急求助'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              '长按按钮启动求助',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: '长按求助',
              size: 160,
              onPressed: () {},
            ),

            const SizedBox(height: 30),

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
