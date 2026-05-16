import 'package:flutter/material.dart';
import '../../services/sos_service.dart';
import '../../routes/app_routes.dart';

class SendSosMessagePage extends StatefulWidget {
  const SendSosMessagePage({super.key});

  @override
  State<SendSosMessagePage> createState() => _SendSosMessagePageState();
}

class _SendSosMessagePageState extends State<SendSosMessagePage> {
  final SosService _sosService = SosService();
  List<Map<String, dynamic>> _contacts = [];
  int _selectedContactIndex = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _sosService.getEmergencyContacts();
    if (contacts.isEmpty) {
      _contacts = [
        {'name': '紧急联系人1', 'phone': '13900000000'}
      ];
    } else {
      _contacts = contacts;
    }
    if (mounted) {
      setState(() {});
    }
  }

  String _generateMessage() {
    const nickname = '用户昵称';
    const location = '深圳市福田区安联大厦SUNNY SAPCE';
    return '【Nestway app】[$nickname]发起了紧急求助，需要帮忙！你是TA的紧急联系人，因此收到此消息。当前位置：$location';
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        await _showSuccessDialog();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.sos,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发送失败，请重试'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '发送成功！',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 16),
          onPressed: _cancel,
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '发送求助短信',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: Container(
        color: const Color(0xFFF3E5F5),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '收件人：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _contacts.isNotEmpty
                                ? _contacts[_selectedContactIndex]['name']
                                : '紧急联系人1',
                            isExpanded: true,
                            alignment: Alignment.centerRight,
                            icon: const Icon(Icons.arrow_drop_down, size: 24),
                            items: _contacts.map((contact) {
                              return DropdownMenuItem<String>(
                                value: contact['name'],
                                child: Text(
                                  contact['name'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedContactIndex = _contacts.indexWhere(
                                  (c) => c['name'] == newValue,
                                );
                                if (_selectedContactIndex < 0) {
                                  _selectedContactIndex = 0;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '正文：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _generateMessage(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _cancel,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _sendMessage,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9C4),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: _isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Text(
                                          '发送',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}