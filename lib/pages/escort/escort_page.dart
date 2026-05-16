import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../mock/mock_contacts.dart';

class EscortPage extends StatefulWidget {
  const EscortPage({super.key});

  @override
  State<EscortPage> createState() => _EscortPageState();
}

class _EscortPageState extends State<EscortPage> {
  final TextEditingController _destinationController = TextEditingController();
  int _selectedMinutes = 15;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '虚拟护送',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 出发地
            _buildInputCard(
              title: '出发地',
              icon: Icons.location_pin,
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    color: Color(0xFFFFE066),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '我的当前位置',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 目的地
            _buildInputCard(
              title: '目的地',
              icon: Icons.search,
              child: TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '输入目的地',
                  hintStyle: TextStyle(color: Colors.black38),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 预计时间
            _buildInputCard(
              title: '预计到达时间',
              icon: Icons.access_time,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE066),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_selectedMinutes分钟',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: const Color(0xFFFFE066),
                      inactiveTrackColor: Colors.grey[200],
                      thumbColor: const Color(0xFFFFE066),
                      overlayColor: const Color(0xFFFFE066).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _selectedMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      onChanged: (value) {
                        setState(() {
                          _selectedMinutes = value.round();
                        });
                      },
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5分钟', style: TextStyle(fontSize: 10, color: Colors.black45)),
                      Text('2小时', style: TextStyle(fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 紧急联系人
            _buildInputCard(
              title: '紧急联系人',
              icon: null,
              trailing: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: const Text(
                  '管理',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
              child: mockContacts.isNotEmpty
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal[300],
                          child: ClipOval(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop',
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mockContacts[0]['name'] as String? ?? '张美美',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPhone(mockContacts[0]['phone'] as String? ?? '13888888888'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.settings,
                          color: Colors.black38,
                          size: 20,
                        ),
                      ],
                    )
                  : const Text('暂无紧急联系人'),
            ),

            const SizedBox(height: 48),

            // 开始护送按钮
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.escortProgress);
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE066),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFE066).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '开始护送',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String phone) {
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
    }
    return phone;
  }

  Widget _buildInputCard({
    required String title,
    IconData? icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.grey[600], size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}