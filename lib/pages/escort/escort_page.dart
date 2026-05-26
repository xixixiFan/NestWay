import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/escort_config.dart';
import '../../routes/app_routes.dart';
import '../../mock/mock_contacts.dart';
import '../../services/location_service.dart';
import '../../services/escort_service.dart';
import 'progress_page.dart';

// 高德 POI 搜索结果
class _PoiResult {
  final String name;
  final String address;
  final String district;
  final double? lat;
  final double? lng;

  _PoiResult({
    required this.name,
    required this.address,
    required this.district,
    this.lat,
    this.lng,
  });

  String get displayAddress =>
      [district, address].where((s) => s.isNotEmpty).join(' ');
}

class EscortPage extends StatefulWidget {
  const EscortPage({super.key});

  @override
  State<EscortPage> createState() => _EscortPageState();
}

class _EscortPageState extends State<EscortPage> {
  final TextEditingController _searchController = TextEditingController();
  final EscortLocationService _locationService = EscortLocationService();
  static const _amapKey = '89ff90f769765ecd5f68e2cb48e283cb';

  int _selectedMinutes = 15;
  LocationPoint? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  // 目的地搜索相关
  _PoiResult? _selectedPoi;       // 已选中的地点
  List<_PoiResult> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // 如果用户修改了已选中的内容，清除选中状态
    if (_selectedPoi != null && query != _selectedPoi!.name) {
      _selectedPoi = null;
    }

    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPoi(query);
    });
  }

  Future<void> _searchPoi(String keyword) async {
    setState(() => _isSearching = true);

    try {
      print('[POI搜索] 关键词: $keyword');
      
      // 如果有当前位置，用城市限定搜索范围
      final cityParam = _currentLocation != null
          ? '&location=${_currentLocation!.longitude},${_currentLocation!.latitude}'
          : '';

      final url = Uri.parse(
        'https://restapi.amap.com/v3/place/text'
        '?key=$_amapKey'
        '&keywords=$keyword'
        '&types='
        '&offset=8'
        '&page=1'
        '&extensions=base'
        '$cityParam',
      );
      print('[POI搜索] 请求URL: $url');

      final response = await http.get(url);
      print('[POI搜索] 响应状态: ${response.statusCode}');
      
      // 确保使用 UTF-8 解码
      final utf8Body = utf8.decode(response.bodyBytes);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8Body);
        print('[POI搜索] 响应: $data');
        
        if (data['status'] == '1' && data['pois'] != null) {
          final pois = data['pois'] as List<dynamic>;
          print('[POI搜索] 找到 ${pois.length} 个POI');
          
          final results = pois.map((poi) {
            final location = poi['location'] as String? ?? '';
            double? lat, lng;
            if (location.contains(',')) {
              final parts = location.split(',');
              lng = double.tryParse(parts[0]);
              lat = double.tryParse(parts[1]);
            }
            
            // 打印每个POI的原始数据
            print('[POI搜索] POI原始数据: name=${poi['name']}, address=${poi['address']}, adname=${poi['adname']}');
            
            return _PoiResult(
              name: poi['name'] as String? ?? '',
              address: poi['address'] as String? ?? '',
              district: poi['adname'] as String? ?? '',
              lat: lat,
              lng: lng,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _suggestions = results;
              _showSuggestions = results.isNotEmpty;
            });
          }
        } else {
          print('[POI搜索] API返回失败: ${data['info']}');
        }
      }
    } catch (e) {
      print('[POI搜索] 异常: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectPoi(_PoiResult poi) {
    setState(() {
      _selectedPoi = poi;
      _showSuggestions = false;
      _suggestions = [];
    });
    _searchController.text = poi.name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: poi.name.length),
    );
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });
    }

    final location = await _locationService.getCurrentLocation();

    if (mounted) {
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
  }

  bool get _canStart =>
      _currentLocation != null &&
      _currentLocation!.latitude != 0 &&
      _selectedPoi != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击空白处收起建议列表
        if (_showSuggestions) {
          setState(() => _showSuggestions = false);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
            style: TextStyle(color: Colors.black, fontSize: 18),
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
                          ? const Text('正在获取位置...',
                              style: TextStyle(color: Colors.black54, fontSize: 14))
                          : _currentLocation != null
                              ? Text(_currentLocation!.address ?? '我的当前位置',
                                  style: const TextStyle(color: Colors.black87, fontSize: 14))
                              : Text(_locationError ?? '无法获取位置',
                                  style: const TextStyle(color: Colors.red, fontSize: 14)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 目的地（带搜索建议）
              _buildInputCard(
                title: '目的地',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 搜索框
                    TextField(
                      controller: _searchController,
                      onTap: () {
                        if (_searchController.text.trim().length >= 2 &&
                            _suggestions.isNotEmpty) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '搜索目的地',
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: const Color(0xFFF6F3F2),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.black38, size: 20),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.black38, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _selectedPoi = null;
                                        _suggestions = [];
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),

                    // 已选中提示
                    if (_selectedPoi != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedPoi!.displayAddress,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // 搜索建议列表
                    if (_showSuggestions && _suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _suggestions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final poi = entry.value;
                            return InkWell(
                              onTap: () => _selectPoi(poi),
                              borderRadius: BorderRadius.vertical(
                                top: i == 0
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottom: i == _suggestions.length - 1
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Color(0xFFFFE066)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            poi.name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (poi.displayAddress.isNotEmpty)
                                            Text(
                                              poi.displayAddress,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 预计时间
              _buildInputCard(
                title: '预计到达时间',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE066),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_selectedMinutes分钟',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        activeTrackColor: const Color(0xFFFFE066),
                        inactiveTrackColor: Colors.grey[200],
                        thumbColor: const Color(0xFFFFE066),
                        overlayColor:
                            const Color(0xFFFFE066).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _selectedMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        onChanged: (value) {
                          setState(() => _selectedMinutes = value.round());
                        },
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5分钟',
                            style: TextStyle(
                                fontSize: 10, color: Colors.black45)),
                        Text('2小时',
                            style: TextStyle(
                                fontSize: 10, color: Colors.black45)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 紧急联系人
              _buildInputCard(
                title: '紧急联系人',
                trailing: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.profile),
                  child: const Text('管理',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 12)),
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
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Colors.white),
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
                                  mockContacts[0]['name'] as String? ??
                                      '张美美',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPhone(mockContacts[0]['phone']
                                          as String? ??
                                      '13888888888'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.profile),
                            child: const Icon(Icons.settings,
                                color: Colors.black38, size: 20),
                          ),
                        ],
                      )
                    : const Text('暂无紧急联系人'),
              ),

              const SizedBox(height: 48),

              // 开始护送按钮
              GestureDetector(
                onTap: _canStart
                    ? () async {
                        final escortId =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        await _locationService.startTracking();

                        final destination = _selectedPoi!.name;

                        final config = EscortConfig(
                          escortId: escortId,
                          destination: destination,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: _currentLocation!,
                          contacts: mockContacts,
                        );

                        await EscortService().startEscort(
                          destination: destination,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: _currentLocation!,
                        );

                        await _locationService.reportEscortStart(
                          escortId: escortId,
                          destination: destination,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: _currentLocation!,
                        );

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProgressPage(config: config),
                            ),
                          );
                        }
                      }
                    : null,
                child: Opacity(
                  opacity: _canStart ? 1.0 : 0.5,
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
                        _isLoadingLocation
                            ? '正在获取位置...'
                            : _selectedPoi == null
                                ? '请选择目的地'
                                : '开始护送',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              Text(title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
