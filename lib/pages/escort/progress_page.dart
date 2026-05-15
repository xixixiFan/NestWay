import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔝 顶部
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '护送进行中',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📦 内容区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 🟡 卡片1：路径
                  _card(
                    child: SizedBox(
                      height: 90,
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.circle, size: 8),
                              SizedBox(width: 8),
                              Text('我的当前位置'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.black12,
                            margin: const EdgeInsets.only(left: 4),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.location_on, size: 14),
                              SizedBox(width: 8),
                              Text('静安区地铁站A口'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🟡 卡片2：倒计时
                  _card(
                    child: SizedBox(
                      height: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '距离预计结束还有',
                            style: TextStyle(color: Colors.black45),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '14分52秒',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '超时未打卡将自动通知紧急联系人',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 标题
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      '紧急联系人',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ),

                  // 🟡 卡片3：联系人
                  _card(
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.pinkAccent,
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('张美美'),
                                SizedBox(height: 4),
                                Text(
                                  '138 **** 5678',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.phone),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔻 底部
            Column(
              children: [
                const Text(
                  '暂停护送',
                  style: TextStyle(color: Colors.black38),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.success);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE066),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          '安全打卡',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 通用卡片组件
  static Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}