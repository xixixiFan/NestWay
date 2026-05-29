import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../models/escort_config.dart';
import '../../routes/app_routes.dart';
import '../../config/amap_config.dart';
import '../../services/location_service.dart';
import '../../services/escort_service.dart';
import '../../services/contacts_provider.dart';
import '../../utils/performance_tracer.dart';
import '../../utils/string_utils.dart';
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
  int _selectedMinutes = 15;
  LocationPoint? _currentLocation;

  // 目的地搜索相关
  _PoiResult? _selectedPoi;       // 已选中的地点
  List<_PoiResult> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _showSuggestions = false;

  // 出发地搜索相关
  final TextEditingController _departureSearchController =
      TextEditingController();
  _PoiResult? _selectedDeparturePoi;
  List<_PoiResult> _departureSuggestions = [];
  bool _isSearchingDeparture = false;
  Timer? _departureDebounce;
  bool _showDepartureSuggestions = false;

  bool _isStarting = false;
  ContactsProvider? _contactsProvider;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _searchController.addListener(_onSearchChanged);
    _departureSearchController.addListener(_onDepartureSearchChanged);
    // 加载真实紧急联系人
    final cp = context.read<ContactsProvider>();
    _contactsProvider = cp;
    if (cp.contacts.isEmpty && !cp.isLoading) {
      cp.loadContacts();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _departureSearchController.removeListener(_onDepartureSearchChanged);
    _departureSearchController.dispose();
    _debounce?.cancel();
    _departureDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (_selectedPoi != null && query == _selectedPoi!.name) return;

    if (_selectedPoi != null) _selectedPoi = null;

    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await _fetchPoiResults(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
          _isSearching = false;
        });
      }
    });
  }

  void _onDepartureSearchChanged() {
    final query = _departureSearchController.text.trim();

    if (_selectedDeparturePoi != null &&
        query == _selectedDeparturePoi!.name) return;

    if (_selectedDeparturePoi != null) _selectedDeparturePoi = null;

    _departureDebounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _departureSuggestions = [];
        _showDepartureSuggestions = false;
      });
      return;
    }

    _departureDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearchingDeparture = true);
      final results = await _fetchPoiResults(query);
      if (mounted) {
        setState(() {
          _departureSuggestions = results;
          _showDepartureSuggestions = results.isNotEmpty;
          _isSearchingDeparture = false;
        });
      }
    });
  }

  Future<List<_PoiResult>> _fetchPoiResults(String keyword) async {
    try {
      final cityParam = _currentLocation != null
          ? '&location=${_currentLocation!.longitude},${_currentLocation!.latitude}'
          : '';

      final url = Uri.parse(
        'https://restapi.amap.com/v3/place/text'
        '?key=$amapApiKey'
        '&keywords=${Uri.encodeQueryComponent(keyword)}'
        '&types='
        '&offset=8'
        '&page=1'
        '&extensions=base'
        '$cityParam',
      );

      final response = await http.get(url);
      final utf8Body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(utf8Body);
        if (data['status'] == '1' && data['pois'] != null) {
          final pois = data['pois'] as List<dynamic>;
          return pois.map((poi) {
            final location = poi['location'] as String? ?? '';
            double? lat, lng;
            if (location.contains(',')) {
              final parts = location.split(',');
              lng = double.tryParse(parts[0]);
              lat = double.tryParse(parts[1]);
            }
            return _PoiResult(
              name: poi['name'] as String? ?? '',
              address: poi['address'] as String? ?? '',
              district: poi['adname'] as String? ?? '',
              lat: lat,
              lng: lng,
            );
          }).toList();
        }
      }
    } catch (e) {
      print('[POI搜索] 异常: $e');
    }
    return [];
  }

  void _selectPoi(_PoiResult poi) {
    _debounce?.cancel();
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

  void _selectDeparturePoi(_PoiResult poi) {
    _departureDebounce?.cancel();
    setState(() {
      _selectedDeparturePoi = poi;
      _showDepartureSuggestions = false;
      _departureSuggestions = [];
    });
    _departureSearchController.text = poi.name;
    _departureSearchController.selection = TextSelection.fromPosition(
      TextPosition(offset: poi.name.length),
    );
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchCurrentLocation() async {
    final t = PerformanceTracer.instance;
    final traceId = t.startTrace('escort_page_init_location',
        input: {'source': 'EscortPage.initState'});
    t.pushTrace(traceId);

    String? locationError;
    try {
    // 获取精准定位（含城市名）用于POI搜索城市范围限定
    final preciseResult = await t.traceAuto('fetch_precise_result',
        () => LocationService().getPreciseLocation());
    final location = await t.traceAuto('fetch_escort_location',
        () => _locationService.getCurrentLocation());

    if (mounted) {
      setState(() {
        if (location != null && location.latitude != 0 && location.longitude != 0) {
          final city = preciseResult.city ?? '';
          final addr = location.address ?? '';
          final fullAddress = city.isNotEmpty && addr.isNotEmpty
              ? '$city $addr'
              : (addr.isNotEmpty ? addr : (city.isNotEmpty ? city : null));
          _currentLocation = LocationPoint(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: location.timestamp,
            address: fullAddress ?? location.address,
          );
        } else if (location != null) {
          _currentLocation = location;
          locationError = location.address ?? '无法获取位置';
        } else {
          locationError = '无法获取位置';
        }
      });
    }
    } finally {
      t.endTrace(traceId, output: {
        'has_location': _currentLocation != null && _currentLocation!.latitude != 0,
        'error': locationError,
      });
    }
  }

  bool get _canStart =>
      _selectedDeparturePoi != null &&
      _selectedDeparturePoi!.lat != null &&
      _selectedDeparturePoi!.lat != 0 &&
      _selectedPoi != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击空白处收起建议列表
        if (_showSuggestions) {
          setState(() => _showSuggestions = false);
        }
        if (_showDepartureSuggestions) {
          setState(() => _showDepartureSuggestions = false);
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
              // 出发地（带搜索建议）
              _buildInputCard(
                title: '出发地',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _departureSearchController,
                      onTap: () {
                        if (_departureSearchController.text.trim().length >= 2 &&
                            _departureSuggestions.isNotEmpty) {
                          setState(() => _showDepartureSuggestions = true);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '搜索出发地',
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: const Color(0xFFF6F3F2),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.black38, size: 20),
                        suffixIcon: _isSearchingDeparture
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _departureSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.black38, size: 18),
                                    onPressed: () {
                                      _departureSearchController.clear();
                                      setState(() {
                                        _selectedDeparturePoi = null;
                                        _departureSuggestions = [];
                                        _showDepartureSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),

                    // 已选中提示
                    if (_selectedDeparturePoi != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedDeparturePoi!.displayAddress,
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
                    if (_showDepartureSuggestions &&
                        _departureSuggestions.isNotEmpty) ...[
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
                          children: _departureSuggestions
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final poi = entry.value;
                            return InkWell(
                              onTap: () => _selectDeparturePoi(poi),
                              borderRadius: BorderRadius.vertical(
                                top: i == 0
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottom: i == _departureSuggestions.length - 1
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.trip_origin,
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
              Consumer<ContactsProvider>(
                builder: (_, cp, __) => _buildInputCard(
                  title: '紧急联系人',
                  trailing: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    child: const Text('管理',
                        style:
                            TextStyle(color: Colors.black54, fontSize: 12)),
                  ),
                  child: cp.contacts.isNotEmpty
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFFFE566),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.teal[300],
                                child: Center(
                                  child: Text(
                                    (cp.contacts[0]['name'] as String? ?? '?')
                                        .characters.first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                    cp.contacts[0]['name'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatPhone(cp.contacts[0]['phone']
                                            as String? ??
                                        ''),
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
                      : const Text('暂无紧急联系人，请先添加'),
                ),
              ),

              const SizedBox(height: 48),

              // 开始护送按钮
              GestureDetector(
                onTap: _canStart && !_isStarting
                    ? () async {
                        setState(() => _isStarting = true);
                        try {
                        await PerformanceTracer.instance.trace(
                          'escort_start_button',
                          () async {
                        final escortId =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        await _locationService.startTracking();

                        final destination = _selectedPoi!.name;

                        final departureLoc = LocationPoint(
                          latitude: _selectedDeparturePoi!.lat!,
                          longitude: _selectedDeparturePoi!.lng!,
                          timestamp: DateTime.now(),
                          address: _selectedDeparturePoi!.name,
                        );

                        final config = EscortConfig(
                          escortId: escortId,
                          destination: destination,
                          destinationLat: _selectedPoi!.lat,
                          destinationLng: _selectedPoi!.lng,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: departureLoc,
                          contacts: _contactsProvider?.contacts ?? [],
                        );

                        await EscortService().startEscort(
                          destination: destination,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: departureLoc,
                        );

                        await _locationService.reportEscortStart(
                          escortId: escortId,
                          destination: destination,
                          estimatedMinutes: _selectedMinutes,
                          startPoint: departureLoc,
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
                          },
                          input: {
                            'destination': _selectedPoi!.name,
                            'estimated_minutes': _selectedMinutes,
                          },
                        );
                        } finally {
                          if (mounted) setState(() => _isStarting = false);
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
                        _isStarting
                            ? '护送启动中...'
                            : _selectedDeparturePoi == null
                                ? '请选择出发地'
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
