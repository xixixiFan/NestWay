import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 城市安全数据模型
class CitySafetyData {
  final String cityName;
  final String riskLevel;
  final double safetyScore;
  final List<String> safetyFeatures;
  final String safetyBrief;
  final List<String> nightTravelTips;
  final List<String> accommodationTips;
  final Map<String, String> emergencyContacts;
  final String? source;
  final String? updateTime;

  CitySafetyData({
    required this.cityName,
    required this.riskLevel,
    required this.safetyScore,
    required this.safetyFeatures,
    required this.safetyBrief,
    required this.nightTravelTips,
    required this.accommodationTips,
    required this.emergencyContacts,
    this.source,
    this.updateTime,
  });
}

class DestinationSafetyPage extends StatefulWidget {
  final String cityName;
  const DestinationSafetyPage({super.key, required this.cityName});

  @override
  State<DestinationSafetyPage> createState() => _DestinationSafetyPageState();
}

class _DestinationSafetyPageState extends State<DestinationSafetyPage> {
  CitySafetyData? _currentData;
  bool _isLoading = false;
  String? _errorMessage;

  static const String apiKey = 'sk-1f17d93786ac413187006742996cac29';
  final String apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  // 热门城市列表（只显示城市名）
  final List<String> hotCities = const [
    '香港', '杭州', '苏州', '天津', '洛阳', '哈尔滨'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSafetyReport(widget.cityName);
  }

  Future<void> _fetchSafetyReport(String place) async {
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = '请配置 API Key';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentData = null;
    });

    const systemPrompt = '''
你是一位资深女性旅行安全专家，熟悉各地文化。用户输入一个具体城市，请生成针对女性独自旅行的安全报告，要求内容具体、有该城市特色，避免空泛套话。
严格按照以下JSON格式返回，不要有任何额外文字：
{
  "place_name": "城市名称",
  "risk_level": "低/中/高",
  "safety_score": 0-10的浮点数,
  "city_features": ["特色1", "特色2", "特色3"],
  "security_brief": "治安简评（100字内，指出常见风险区域及女性注意事项）",
  "night_advice": "3~5条夜间出行建议，用句号分隔，结合该城市夜生活特点",
  "accommodation_tips": "3~5条住宿建议，用句号分隔，指出不同区域优劣",
  "police_phone": "报警电话",
  "ambulance_phone": "急救电话",
  "local_hotline": "当地旅游服务热线（若无则留空）"
}
''';

    final requestBody = {
      "model": "deepseek-chat",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": place}
      ],
      "temperature": 0.3,
      "max_tokens": 2000,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final modelOutput = result['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(modelOutput);
        if (jsonMatch == null) throw Exception('未找到JSON');
        final safetyReport = jsonDecode(jsonMatch.group(0)!);

        final placeName = safetyReport['place_name'] ?? place;
        final risk = safetyReport['risk_level'] ?? '低';
        final score = (safetyReport['safety_score'] as num?)?.toDouble() ?? 5.0;
        final displayScore = (score / 2).toDouble();
        final features = List<String>.from(safetyReport['city_features'] ?? ['暂无数据']);
        final brief = safetyReport['security_brief'] ?? '暂无治安简评';
        final nightAdviceRaw = safetyReport['night_advice'] ?? '';
        final accommodationRaw = safetyReport['accommodation_tips'] ?? '';
        final policePhone = safetyReport['police_phone']?.toString() ?? '110';
        final ambulancePhone = safetyReport['ambulance_phone']?.toString() ?? '120';
        final localHotline = safetyReport['local_hotline']?.toString() ?? '';

        List<String> splitText(String text) {
          if (text.isEmpty) return ['暂无信息'];
          List<String> parts = text.split(RegExp(r'[；;。.\n]'));
          parts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
          if (parts.isEmpty) return [text];
          return parts;
        }

        final nightTips = splitText(nightAdviceRaw);
        final accommodationTips = splitText(accommodationRaw);

        final Map<String, String> emergencyContacts = {
          '公安报警': policePhone,
          '医疗急救': ambulancePhone,
        };
        if (localHotline.isNotEmpty) {
          emergencyContacts['本地热线'] = localHotline;
        }

        setState(() {
          _currentData = CitySafetyData(
            cityName: placeName,
            riskLevel: risk,
            safetyScore: displayScore,
            safetyFeatures: features,
            safetyBrief: brief,
            nightTravelTips: nightTips,
            accommodationTips: accommodationTips,
            emergencyContacts: emergencyContacts,
            source: 'AI 实时生成',
            updateTime: DateTime.now().toLocal().toString().substring(0, 16),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'AI请求失败: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9FF),
      appBar: AppBar(
        title: const Text('目的地安全预警'),
        backgroundColor: const Color(0xFFEFE9FF),
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchSafetyReport(widget.cityName),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _currentData == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('暂无数据', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _buildSafetyContent(),
    );
  }

  Widget _buildSafetyContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 16),
        _buildHotCitiesRow(),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "城市安全特点",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentData!.safetyFeatures
                .map((feature) => Chip(
                      label: Text(feature),
                      backgroundColor: const Color(0xFFEFE9FF),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "治安状况简评",
          child: Text(_currentData!.safetyBrief),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "夜间出行建议",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _currentData!.nightTravelTips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• "),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "住宿安全建议",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _currentData!.accommodationTips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• "),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "报警与急救",
          child: Column(
            children: [
              Row(
                children: _currentData!.emergencyContacts.entries.take(2).map((entry) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(entry.key),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_currentData!.emergencyContacts.length > 2) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_currentData!.emergencyContacts.entries.elementAt(2).key),
                      const SizedBox(height: 4),
                      Text(
                        _currentData!.emergencyContacts.entries.elementAt(2).value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_currentData!.source != null || _currentData!.updateTime != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "数据来源：${_currentData!.source ?? '未知'} | 更新时间：${_currentData!.updateTime ?? ''}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // 热门城市标签：文字水平垂直居中
  Widget _buildHotCitiesRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hotCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final city = hotCities[index];
          final isCurrentCity = _currentData?.cityName == city;
          return GestureDetector(
            onTap: () => _fetchSafetyReport(city),
            child: Container(
              alignment: Alignment.center,               // 垂直水平居中
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentCity ? const Color(0xFF8022FF) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isCurrentCity ? const Color(0xFF8022FF) : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              child: Text(
                city,
                textAlign: TextAlign.center,            // 文字水平居中
                style: TextStyle(
                  fontSize: 14,
                  color: isCurrentCity ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 头部卡片：评分数字黑色加粗
  Widget _buildHeaderCard() {
    String riskDisplay = _currentData!.riskLevel;
    Color riskBgColor;
    Color riskTextColor;
    if (riskDisplay == '低') {
      riskDisplay = '低风险';
      riskBgColor = Colors.green.shade50;
      riskTextColor = Colors.green.shade800;
    } else if (riskDisplay == '中') {
      riskDisplay = '中风险';
      riskBgColor = Colors.orange.shade50;
      riskTextColor = Colors.orange.shade800;
    } else if (riskDisplay == '高') {
      riskDisplay = '高风险';
      riskBgColor = Colors.red.shade50;
      riskTextColor = Colors.red.shade800;
    } else {
      riskBgColor = Colors.grey.shade50;
      riskTextColor = Colors.grey.shade800;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _currentData!.cityName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: riskBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                riskDisplay,
                style: TextStyle(color: riskTextColor, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(5, (index) {
              if (index < _currentData!.safetyScore.floor()) {
                return const Icon(Icons.star, color: Colors.amber, size: 16);
              } else if (index < _currentData!.safetyScore) {
                return const Icon(Icons.star_half, color: Colors.amber, size: 16);
              } else {
                return const Icon(Icons.star_border, color: Colors.grey, size: 16);
              }
            }),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  const TextSpan(text: '安全评分 ', style: TextStyle(color: Colors.grey)),
                  TextSpan(
                    text: _currentData!.safetyScore.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const TextSpan(text: '/5', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 219),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}