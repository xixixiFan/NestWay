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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().loadContacts();
      _loadUserName();
    });
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
    return '【NestWay】紧急求助！$_userName发起了SOS求助，您是TA的紧急联系人。'
        '当前位置：$_location$coords。请立即确认TA的安全！';
  }

  Future<void> _sendMessage() async {
    if (_step != _SendingStep.idle) return;

    final contacts = context.read<ContactsProvider>().contacts;
    if (contacts.isEmpty) {
      _showNoContactsDialog();
      return;
    }

    setState(() => _step = _SendingStep.locating);

    final locationData = await _sosService.getCurrentLocationWithAddress();
    final address = locationData['address'] as String?;
    final lat = locationData['latitude'] as double?;
    final lng = locationData['longitude'] as double?;

    if (address == null && lat == null) {
      if (mounted) {
        setState(() => _step = _SendingStep.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('获取位置失败，请检查定位权限'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _location = address ??
          '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}';
      _latitude = lat;
      _longitude = lng;
      _step = _SendingStep.sending;
    });

    final phones = contacts
        .map((c) => c['phone'] as String?)
        .whereType<String>()
        .toList();

    final coords = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
        : '';

    final success = await _sosService.sendSosSms(
      phones: phones,
      name: _userName,
      location: _location,
      coords: coords,
    );

    if (mounted) {
      if (success) {
        await _showSuccessDialog();
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 70, color: Color(0xFF4CAF50)),
                SizedBox(height: 20),
                Text(
                  '已发送！',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '求助短信已发送给所有紧急联系人',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '发送求助短信',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ),
        centerTitle: false,
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
            ...contacts.asMap().entries.map((entry) {
              final contact = entry.value;
              final name = contact['name'] as String? ?? '';
              final phone = contact['phone'] as String? ?? '';
              return Container(
                margin: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFFF9C4),
                      child:
                          Icon(Icons.person, size: 18, color: Colors.black54),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            phone,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_outline,
                        size: 20, color: Color(0xFFFFE066)),
                  ],
                ),
              );
            }),
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
              _step == _SendingStep.idle && _location.isEmpty
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
    final isLoading = _step != _SendingStep.idle;
    final noContacts = contacts.isEmpty;

    String buttonText;
    if (_step == _SendingStep.locating) {
      buttonText = '正在获取位置...';
    } else if (_step == _SendingStep.sending) {
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
            onTap: (isLoading || noContacts) ? null : _sendMessage,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: (isLoading || noContacts)
                    ? const Color(0xFFFFF9C4).withValues(alpha: 0.5)
                    : const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: isLoading
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
                          color: noContacts ? Colors.grey : Colors.black,
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
