import 'package:flutter/material.dart';
import '../safety/destination_safety_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> hotDestinations = [
    '长沙橘子洲头',
    '北京故宫',
    '深圳人才公园',
    '长白山',
    '上海迪士尼',
    '香港迪士尼',
  ];

  void _searchDestination(String destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSafetyPage(cityName: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE8FE),
      appBar: AppBar(
        title: const Text('目的地预警'),
        backgroundColor: const Color(0xFFEFE9FF),
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // 顶部：爱心 + 栖途 + 右侧两行标语（爱心和栖途垂直居中）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
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
            const SizedBox(height: 32),
            // 三个功能卡片（上下排列）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFeatureCard(
                    icon: Icons.sos,
                    title: '智能分级SOS',
                    description: '根据危险等级自动匹配响应方案，紧急时一键触发多级联动',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'AI虚拟护送',
                    description: '夜间回家不孤单，智能语音陪伴+实时位置追踪，让家人放心',
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
                onSubmitted: _searchDestination,
              ),
            ),
            const SizedBox(height: 20),
            // 热门目的地标题
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('热门目的地', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            // 热门目的地标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: hotDestinations.map((destination) => GestureDetector(
                  onTap: () => _searchDestination(destination),
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
                    child: Text(destination, style: const TextStyle(fontSize: 14)),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
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
    );
  }
}