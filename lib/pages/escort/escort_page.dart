import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/escort_config.dart';
import '../../routes/app_routes.dart';
import '../../mock/mock_contacts.dart';
import '../../services/location_service.dart';
import '../../services/escort_service.dart';
import 'progress_page.dart';

class EscortPage extends StatefulWidget {
  const EscortPage({super.key});

  @override
  State<EscortPage> createState() => _EscortPageState();
}

class _EscortPageState extends State<EscortPage> {
  final TextEditingController _destinationController = TextEditingController();
  final EscortLocationService _locationService = EscortLocationService();
  int _selectedMinutes = 15;
  LocationPoint? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final location = await _locationService.getCurrentLocation();

    setState(() {
      _isLoadingLocation = false;
      if (location != null && location.latitude != 0 && location.longitude != 0) {
        _currentLocation = location;
        _locationError = null;
      } else if (location != null) {
        _currentLocation = location;
        _locationError = location.address ?? '无法获取位置';
      } else {
        _locationError = '无法获取位置';
      }
    });
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
              icon: null,
              child: Row(
                children: [
                  _isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _currentLocation != null
                              ? Icons.location_on
                              : Icons.location_off,
                          color: const Color(0xFFFFE066),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isLoadingLocation
                        ? const Text(
                            '正在获取位置...',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          )
                        : _currentLocation != null
                            ? Text(
                                _currentLocation!.address ?? '我的当前位置',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              )
                            : Text(
                                _locationError ?? '无法获取位置',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.expand_more, size: 20),
                    onPressed: _isLoadingLocation ? null : _fetchCurrentLocation,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 目的地
            _buildInputCard(
              title: '目的地',
              icon: null,
              child: TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '输入目的地',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFF6F3F2),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 预计时间
            _buildInputCard(
              title: '预计到达时间',
              icon: null,
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
                          radius: 26,
                          backgroundColor: const Color(0xFFFFE566),
                          child: CircleAvatar(
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
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.black38,
                            size: 20,
                          ),
                        ),
                      ],
                    )
                  : const Text('暂无紧急联系人'),
            ),

            const SizedBox(height: 48),

            // 开始护送按钮
            GestureDetector(
              onTap: (_currentLocation == null || _currentLocation!.latitude == 0)
                  ? null
                  : () async {
                      final escortId = DateTime.now().millisecondsSinceEpoch.toString();
                      await _locationService.startTracking();

                      final config = EscortConfig(
                        escortId: escortId,
                        destination: _destinationController.text.isEmpty
                            ? '未指定目的地'
                            : _destinationController.text,
                        estimatedMinutes: _selectedMinutes,
                        startPoint: _currentLocation!,
                        contacts: mockContacts,
                      );

                      // 写入数据库
                      await EscortService().startEscort(
                        escortId: escortId,
                        destination: config.destination,
                        estimatedMinutes: _selectedMinutes,
                        startPoint: _currentLocation!,
                        contacts: mockContacts,
                      );

                      await _locationService.reportEscortStart(
                        escortId: escortId,
                        destination: config.destination,
                        estimatedMinutes: _selectedMinutes,
                        startPoint: _currentLocation!,
                      );
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgressPage(config: config),
                          ),
                        );
                      }
                    },
              child: Opacity(
                opacity: _currentLocation == null ? 0.5 : 1.0,
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
                  child: Center(
                    child: Text(
                      _currentLocation == null ? '正在获取位置...' : '开始护送',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
        borderRadius: BorderRadius.circular(32),
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