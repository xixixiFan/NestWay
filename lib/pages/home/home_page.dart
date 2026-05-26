import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav.dart';
import '../safety/destination_safety_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  // 使用 feature/safety-profile 分支中的热门城市列表
  final List<String> hotCities = [
    '深圳', '长沙', '北京', '香港',
    '杭州', '苏州', '天津', '洛阳',
    '哈尔滨', '上海',
  ];

  void _searchCity(String city) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSafetyPage(cityName: city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // 栖途品牌区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.black, size: 32),
                    const SizedBox(width: 8),
                    const Text(
                      '栖途',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '你在哪里，我就在哪里',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI智能守护，全程温暖相伴',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 城市安全状态
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text('深圳 · 当前安全', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 虚拟护送大按钮
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.escort);
                  },
                  child: Container(
                    width: 160,
                    height: 160,
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
                        Icon(Icons.shield, size: 48, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  '虚拟护送',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  '设置目的地，全程守护你',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),

              const SizedBox(height: 32),

              // 三个功能卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.sos,
                      title: '智能分级SOS',
                      description: '根据危险等级自动匹配响应方案，紧急时一键触发多级联动',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.sos);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.people,
                      title: 'AI虚拟护送',
                      description: '夜间回家不孤单，智能语音陪伴+实时位置追踪，让家人放心',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.escort);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.warning,
                      title: '目的地预警',
                      description: '出发前了解目的地安全状况，提前规划，旅途更安心',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 搜索栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索城市或目的地',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _searchCity,
                ),
              ),

              const SizedBox(height: 20),

              // 热门目的地标题
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('热门城市', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 12),

              // 热门城市标签（使用 feature/safety-profile 的城市列表）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: hotCities.map((city) => GestureDetector(
                    onTap: () => _searchCity(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(city, style: const TextStyle(fontSize: 14)),
                    ),
                  )).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // 底部导航栏
              const AppBottomNav(currentIndex: 0),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFE91E63)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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