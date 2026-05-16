import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('phone', user.phone)
            .single();

        if (response.data == null) {
          await Supabase.instance.client.from('users').insert({
            'id': int.parse(user.id),
            'name': _nameController.text.isNotEmpty ? _nameController.text : '用户',
            'phone': user.phone,
            'is_verified': true,
          });
        }
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/sos', (route) => false);
      }
    } catch (e) {
      print('注册完成失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        ),
      ),
    );
  }
}
