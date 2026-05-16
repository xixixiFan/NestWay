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

  // 只保留四个热门目的地
  final List<String> hotDestinations = [
    '长沙橘子洲头',
    '北京故宫',
    '深圳人才公园',
    '长白山',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSafetyReport(widget.cityName);
  }

  Future<void> _fetchSafetyReport(String place) async {
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = '请配置 API Key，运行命令：flutter run --dart-define=DEEPSEEK_API_KEY=你的密钥';
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
你是女性旅行安全专家。用户将输入一个具体地点，请生成该地点的女性独自旅行安全报告，严格按照以下JSON格式返回，不要返回任何其他内容：
{
  "place_name": "地点名称",
  "risk_level": "低",
  "safety_score": 0-10的浮点数,
  "city_features": ["特点1", "特点2", "特点3"],
  "security_brief": "治安状况简评（100字以内）",
  "night_advice": "夜间出行建议（用句号或分号分隔多个要点）",
  "accommodation_tips": "住宿安全建议（用句号或分号分隔多个要点）",
  "police_phone": "当地报警电话",
  "ambulance_phone": "急救电话",
  "local_hotline": "本地热线（如市长热线）"
}
''';

    final requestBody = {
      "model": "deepseek-chat",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": place}
      ],
      "temperature": 0.1,
      "max_tokens": 1500,
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
        // 横向滚动热门目的地标签（四个）
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hotDestinations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, idx) {
              final city = hotDestinations[idx];
              final isSelected = _currentData?.cityName == city;
              return GestureDetector(
                onTap: () => _fetchSafetyReport(city),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF8022FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8022FF) : Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    city,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
          title: "住宿到达注意事项",
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
            Text(
              "安全评分 ${_currentData!.safetyScore.toStringAsFixed(1)}/5",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
      width: 390,
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