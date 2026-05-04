import 'package:flutter/material.dart';
import '../../mock/mock_user.dart';
import '../../mock/mock_contacts.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  int calculateDays(String createdAt) {
    final created = DateTime.parse(createdAt);
    final now = DateTime.now();
    return now.difference(created).inDays;
  }

  @override
  Widget build(BuildContext context) {
    // mock 数据怎么用
    final user = mockUser;
    final contacts = mockContacts;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6), // 淡紫色背景
      body: SafeArea(
        child: Column(
          children: [
            // 可滚动区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 顶部标题
                    const Text(
                      "我的",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // 👤 用户卡片
                    _buildUserCard(user),

                    const SizedBox(height: 16),

                    // 🛡 守护状态
                    _buildGuardCard(user),

                    const SizedBox(height: 16),

                    // 📞 紧急联系人
                    _buildContactsCard(contacts),

                    const SizedBox(height: 16),

                    // 🚪 退出登录
                    const Text(
                      "退出当前账号",
                      style: TextStyle(color: Colors.red),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 底部导航固定在底部
            const AppBottomNav(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  // 👤 用户卡片
  Widget _buildUserCard(Map user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.pinkAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user["name"],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.circle, size: 8, color: Colors.green),
                  SizedBox(width: 4),
                  Text("账号已验证", style: TextStyle(fontSize: 12)),
                ],
              )
            ],
          ),

          const Spacer(),

          const Icon(Icons.edit, color: Colors.grey),
        ],
      ),
    );
  }

  // 🛡 守护状态
  Widget _buildGuardCard(Map user) {
    final days = calculateDays(user["created_at"]);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.amber,
            child: Icon(Icons.shield, color: Colors.black),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("守护状态"),
              const SizedBox(height: 4),
              Text("已守护你 $days 天"),
            ],
          ),

          const Spacer(),

          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  // 📞 联系人卡片
  Widget _buildContactsCard(List contacts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        children: [
          Row(
            children: const [
              Text("紧急联系人"),
              Spacer(),
              Text("管理", style: TextStyle(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 12),

          ...contacts.map((c) => _buildContactItem(c)).toList(),

          const SizedBox(height: 12),

          // 添加按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text("+ 添加联系人"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactItem(Map contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person, size: 16),
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact["name"]),
              Text(
                contact["phone"],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),

          const Spacer(),

          const Icon(Icons.phone, size: 18),
        ],
      ),
    );
  }

  // 🎨 统一卡片样式
  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }
}