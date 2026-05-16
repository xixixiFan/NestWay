import 'package:flutter/material.dart';
import '../../mock/mock_user.dart';
import '../../mock/mock_contacts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _userName;
  late List<Map<dynamic, dynamic>> _contacts;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 修正：显式转换为 String
    _userName = mockUser['name'] as String? ?? '用户';
    // 确保类型匹配
    _contacts = List<Map<dynamic, dynamic>>.from(
      mockContacts.map((c) => Map<dynamic, dynamic>.from(c))
    );
  }

  int calculateDays(String createdAt) {
    final created = DateTime.parse(createdAt);
    final now = DateTime.now();
    return now.difference(created).inDays;
  }

  void _editName() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入新昵称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _userName = newName;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加紧急联系人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '手机号'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                setState(() {
                  _contacts.add({'name': name, 'phone': phone});
                });
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = mockUser;
    final avatarUrl = user['avatar_url'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text("我的", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildUserCard(avatarUrl),
                    const SizedBox(height: 16),
                    _buildGuardCard(user),
                    const SizedBox(height: 16),
                    _buildContactsCard(),
                    const SizedBox(height: 16),
                    const Text("退出当前账号", style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String avatarUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.pinkAccent,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text("账号已验证", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _editName,
            child: const Icon(Icons.edit, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardCard(Map user) {
    final days = calculateDays(user["created_at"]);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.shield, color: Colors.black)),
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

  Widget _buildContactsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        children: [
          Row(
            children: const [Text("紧急联系人"), Spacer(), Text("管理", style: TextStyle(color: Colors.grey))],
          ),
          const SizedBox(height: 12),
          ..._contacts.asMap().entries.map((entry) {
            final idx = entry.key;
            final contact = entry.value;
            return _buildContactItem(contact, idx);
          }).toList(),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showAddContactDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text("+ 添加联系人")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(Map<dynamic, dynamic> contact, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact["name"]?.toString() ?? ""),
                Text(contact["phone"]?.toString() ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteContact(index),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }
}
