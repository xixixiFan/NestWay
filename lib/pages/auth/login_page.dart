import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/demo_users.dart';
import '../../services/auth_provider.dart';
import '../../services/sos_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _showCodeInput = false;
  String? _verificationId;

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: '+86${_phoneController.text}',
        channel: OtpChannel.sms,
      );

      setState(() {
        _showCodeInput = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送验证码失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_codeController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: '+86${_phoneController.text}',
        token: _codeController.text,
        type: OtpType.sms,
      );

      await _completeRegistration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('验证失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeRegistration() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.phone != null) {
        final userId = int.parse(user.id);
        
        try {
          final response = await Supabase.instance.client
              .from('users')
              .select()
              .eq('phone', user.phone!)
              .single();

          if (response == null) {
            await Supabase.instance.client.from('users').insert({
              'id': userId,
              'name': _nameController.text.isNotEmpty ? _nameController.text : '用户',
              'phone': user.phone,
              'is_verified': true,
            });
          }
        } catch (_) {
          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'name': _nameController.text.isNotEmpty ? _nameController.text : '用户',
            'phone': user.phone,
            'is_verified': true,
          });
        }
        
        // 设置 SosService 的 currentUserId
        SosService().currentUserId = userId;

        // 持久化 OTP 登录状态，重启后可自动恢复
        if (mounted) {
          final displayName = _nameController.text.isNotEmpty ? _nameController.text : '用户';
          context.read<AuthProvider>().loginAsOtpUser(userId, displayName, user.phone!);
        }
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      print('注册完成失败: $e');
    }
  }

  void _loginAsDemo(int userId) {
    context.read<AuthProvider>().loginAsDemoUser(userId);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final demoUserList = demoUsers;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                '栖途 NestWay',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFE066),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '女性独旅安全守护',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!_showCodeInput) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: '手机号',
                          prefixText: '+86 ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '昵称（选填）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_showCodeInput ? _verifyOtp : _sendOtp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE066),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(_showCodeInput ? '确认验证' : '获取验证码'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_showCodeInput)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showCodeInput = false;
                      _codeController.clear();
                    });
                  },
                  child: const Text('重新获取验证码'),
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '演示模式（跳过短信验证）',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: demoUserList.map((user) {
                    final name = user['name'] as String? ?? '';
                    final phone = user['phone'] as String? ?? '';
                    final userId = user['id'] as int? ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => _loginAsDemo(userId),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE066)),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFFFFF9C4),
                                child: Icon(Icons.person, color: Colors.black54, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '点击登录',
                                style: TextStyle(fontSize: 10, color: Color(0xFFFFE066)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
