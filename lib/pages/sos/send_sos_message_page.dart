import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/contacts_provider.dart';
import '../../services/sos_service.dart';
import '../../routes/app_routes.dart';

enum _SendingStep { idle, locating, sending }

class SendSosMessagePage extends StatefulWidget {
  const SendSosMessagePage({super.key});

  @override
  State<SendSosMessagePage> createState() => _SendSosMessagePageState();
}

class _SendSosMessagePageState extends State<SendSosMessagePage> {
  final SosService _sosService = SosService();
  _SendingStep _step = _SendingStep.idle;

  String _userName = '用户';
  String _location = '';
  double? _latitude;
  double? _longitude;
  
  // 选中的联系人ID（单选）
  int? _selectedContactId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().loadContacts();
      _loadUserName();
      _initializeDefaultContact();
    });
    _autoFetchLocation();
  }

  Future<void> _autoFetchLocation() async {
    try {
      setState(() => _step = _SendingStep.locating);
      final locationData = await _sosService.getCurrentLocationWithAddress();
      final address = locationData['address'] as String?;
      final lat = locationData['latitude'] as double?;
      final lng = locationData['longitude'] as double?;

      if (mounted) {
        setState(() {
          if (address != null) {
            _location = address;
          }
          _latitude = lat;
          _longitude = lng;
          _step = _SendingStep.idle;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _SendingStep.idle);
      }
    }
  }

  // 初始化默认选中第一个联系人
  void _initializeDefaultContact() {
    final contacts = context.read<ContactsProvider>().contacts;
    if (contacts.isNotEmpty) {
      final firstContact = contacts.first;
      final contactId = firstContact['id'] as int?;
      if (contactId != null) {
        setState(() {
          _selectedContactId = contactId;
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    final name = await _sosService.getUserDisplayName();
    if (mounted) {
      setState(() => _userName = name);
    }
  }

  String _generateMessage() {
    final coords = (_latitude != null && _longitude != null)
        ? '（${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}）'
        : '';
    final locationWithCoords = _location.isNotEmpty 
        ? '$_location$coords' 
        : '位置获取中...';
    return '【Nestway app】$_userName向你发送了实时位置，需要帮忙！你是TA的紧急联系人，因此收到此信息。当前位置：$locationWithCoords';
  }

  Future<void> _sendMessage() async {
    if (_step != _SendingStep.idle) return;

    final contacts = context.read<ContactsProvider>().contacts;
    if (contacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    if (_selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择一个联系人'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('位置尚未获取，请稍候重试'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _step = _SendingStep.sending);

    final selectedContact = contacts.firstWhere(
      (c) => c['id'] == _selectedContactId,
      orElse: () => {},
    );

    final phone = selectedContact['phone'] as String?;
    if (phone == null) {
      if (mounted) {
        setState(() => _step = _SendingStep.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('联系人电话号码无效'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final coords = (_latitude != null && _longitude != null)
        ? '${_latitude!.toStringAsFixed(6)},${_longitude!.toStringAsFixed(6)}'
        : null;

    final success = await _sosService.sendSosSms(
      phones: [phone],
      name: _userName,
      location: _location,
      coords: coords,
    );

    if (mounted) {
      if (success) {
        await _showSuccessDialog(selectedContact['name'] as String? ?? '联系人');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.sos,
          (route) => false,
        );
      } else {
        setState(() => _step = _SendingStep.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('短信发送失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNoContactsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('没有紧急联系人'),
        content: const Text('请先添加紧急联系人，然后再发送求助短信。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.emergencyContacts);
            },
            child: const Text('去添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(String contactName) async {
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
                const Icon(Icons.check_circle, size: 70, color: Color(0xFF4CAF50)),
                const SizedBox(height: 20),
                const Text(
                  '已发送！',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '求助短信已发送给 $contactName',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    final contacts = context.watch<ContactsProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 16),
          onPressed: _cancel,
        ),
        title: const Text(
          '发送求助短信',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.emergencyContacts);
            },
            tooltip: '管理紧急联系人',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF3E5F5),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildContactsSection(contacts),
                const SizedBox(height: 16),
                _buildMessagePreview(),
                const SizedBox(height: 24),
                _buildSendButton(contacts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsSection(List<Map<String, dynamic>> contacts) {
    // 确保在联系人加载后初始化默认选中
    if (contacts.isNotEmpty && _selectedContactId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstContact = contacts.first;
        final contactId = firstContact['id'] as int?;
        if (contactId != null && mounted) {
          setState(() {
            _selectedContactId = contactId;
          });
        }
      });
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '收件人：',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                '共 ${contacts.length} 人',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '暂无紧急联系人，请先添加',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.emergencyContacts,
                      );
                    },
                    child: const Text('去添加'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedContactId,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  items: contacts.map((contact) {
                    final name = contact['name'] as String? ?? '';
                    final phone = contact['phone'] as String? ?? '';
                    final contactId = contact['id'] as int?;
                    final sortOrder = contact['sort_order'] as int? ?? 0;
                    
                    return DropdownMenuItem<int>(
                      value: contactId,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFFFF9C4),
                            child: sortOrder == 1
                                ? const Icon(Icons.star, size: 16, color: Colors.black54)
                                : const Icon(Icons.person, size: 16, color: Colors.black54),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (sortOrder == 1) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE066),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: const Text(
                                          '顺位1',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedContactId = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '短信预览：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _location.isEmpty
                  ? '获取位置后将自动填入当前位置信息'
                  : _generateMessage(),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: _location.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(List<Map<String, dynamic>> contacts) {
    final isLocating = _step == _SendingStep.locating;
    final isSending = _step == _SendingStep.sending;
    final noContacts = contacts.isEmpty;

    String buttonText;
    if (isLocating) {
      buttonText = '正在获取位置...';
    } else if (isSending) {
      buttonText = '正在发送短信...';
    } else {
      buttonText = noContacts ? '请先添加联系人' : '发送求助短信';
    }

    return Row(
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
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: const Center(
                child: Text('取消',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: (isLocating || isSending || noContacts) ? null : _sendMessage,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: (isLocating || isSending || noContacts)
                    ? const Color(0xFFFFF9C4).withValues(alpha: 0.5)
                    : const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: (isLocating || noContacts) ? Colors.grey : Colors.black,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
