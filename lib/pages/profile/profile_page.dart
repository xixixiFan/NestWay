import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_provider.dart';
import '../../services/contacts_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _userName;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 头像相关状态
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _userName = user?['name'] as String? ?? '用户';
    _avatarUrl = user?['avatar_url'] as String?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().loadContacts();
    });
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
                // 可选：调用后端更新昵称
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ================= 头像选择（仅本地预览，不真正上传服务器） =================
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    // 模拟上传延时（实际应调用后端接口）
    await Future.delayed(const Duration(milliseconds: 800));

    // 临时使用本地文件路径作为头像（仅用于演示，刷新后丢失）
    setState(() {
      _avatarUrl = pickedFile.path;
      _isUploading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('头像已更新（本地预览，未上传服务器）'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ================= 原有联系人逻辑 =================
  Future<void> _showAddContactDialog() async {
    _nameController.clear();
    _phoneController.clear();

    await showDialog(
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
            onPressed: () async {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                final provider = context.read<ContactsProvider>();
                final success = await provider.addContact(
                  name: name,
                  phone: phone,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加成功'), backgroundColor: Colors.green),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser ?? {};
    // 优先使用本地选择的头像，否则使用服务器返回的头像
    final displayAvatarUrl = _avatarUrl ?? user['avatar_url'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 16),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          },
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '我的',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildUserCard(displayAvatarUrl),
                    const SizedBox(height: 16),
                    _buildGuardCard(user),
                    const SizedBox(height: 16),
                    _buildContactsCard(),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      child: const Text("退出当前账号", style: TextStyle(color: Colors.red)),
                    ),
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
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.pinkAccent,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? (avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl)
                          : FileImage(File(avatarUrl)) as ImageProvider)
                      : null,
                  child: avatarUrl.isEmpty && !_isUploading
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
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
    final days = calculateDays(user["created_at"] as String? ?? '2024-01-01T00:00:00Z');
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
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: _cardStyle(),
          child: Column(
            children: [
              Row(
                children: [
                  const Text("紧急联系人"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.emergencyContacts);
                    },
                    child: const Text("管理", style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...provider.contacts.asMap().entries.map((entry) {
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
      },
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Text(
              contact['name'].toString().substring(0, 1),
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
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
            onPressed: () async {
              final success = await context.read<ContactsProvider>().deleteContact(contact['id'] as int);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功'), backgroundColor: Colors.green),
                );
              }
            },
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