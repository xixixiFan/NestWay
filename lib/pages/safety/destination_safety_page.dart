import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DestinationSafetyPage extends StatefulWidget {
  const DestinationSafetyPage({super.key});

  @override
  State<DestinationSafetyPage> createState() => _DestinationSafetyPageState();
}

class _DestinationSafetyPageState extends State<DestinationSafetyPage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? _safetyData;
  bool _isLoading = false;
  String? _errorMessage;

  // ⚠️ 从环境变量读取 API Key，硬编码不留痕迹
  static const String apiKey = String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  final String apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  Future<void> _fetchSafetyReport(String city) async {
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
      _safetyData = null;
    });

    const systemPrompt = '''
你是女性旅行安全专家。用户将输入一个城市名，请生成该城市最新的女性独自旅行安全信息，并严格按照以下JSON格式返回，不要返回任何其他内容：
{
  "safety_score": 0-100的整数,
  "risk_level": "低",
  "night_advice": "夜间出行建议",
  "street_condition": "街道情况简短描述",
  "accommodation_tips": "住宿安全建议",
  "police_phone": "报警电话",
  "ambulance_phone": "急救电话",
  "women_review_summary": "女性旅行者评价摘要"
}
注意：请根据你的知识给出合理数据，无需联网搜索。
''';

    final requestBody = {
      "model": "deepseek-chat",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": "$city市"}
      ],
      "temperature": 0.1,
      "max_tokens": 2000,
      "response_format": {"type": "json_object"}
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
        setState(() {
          _safetyData = safetyReport;
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

  void _search() {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = '请输入城市名称';
      });
      return;
    }
    _fetchSafetyReport(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目的地安全预警'),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: '输入城市名，如 杭州',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                  child: const Text('AI 分析'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
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
                              onPressed: _search,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _safetyData == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('输入城市名称，获取安全报告'),
                              ],
                            ),
                          )
                        : _buildSafetyCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    final data = _safetyData!;
    final score = data['safety_score'] ?? 0;
    final risk = data['risk_level'] ?? '未知';
    final nightAdvice = data['night_advice'] ?? '暂无信息';
    final streetCondition = data['street_condition'] ?? '暂无信息';
    final accommodationTips = data['accommodation_tips'] ?? '暂无信息';
    final policePhone = data['police_phone'] ?? '110';
    final ambulancePhone = data['ambulance_phone'] ?? '120';
    final womenReview = data['women_review_summary'] ?? '暂无评价';

    Color riskColor = Colors.green;
    if (risk == '中') riskColor = Colors.orange;
    if (risk == '高') riskColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.pink),
                  const SizedBox(width: 8),
                  Text(_cityController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Chip(
                    label: Text('$score 分'),
                    backgroundColor: score >= 80 ? Colors.green[100] : (score >= 60 ? Colors.orange[100] : Colors.red[100]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('整体治安评级：$risk风险', style: TextStyle(color: riskColor)),
              ),
              const SizedBox(height: 20),
              _buildInfoTile(Icons.nightlight_round, '夜间出行建议', nightAdvice),
              _buildInfoTile(Icons.streetview, '街道情况', streetCondition),
              _buildInfoTile(Icons.hotel, '住宿注意事项', accommodationTips),
              _buildInfoTile(Icons.local_police, '报警电话', policePhone),
              _buildInfoTile(Icons.local_hospital, '急救电话', ambulancePhone),
              _buildInfoTile(Icons.comment, '女性旅行者反馈', womenReview),
              const SizedBox(height: 16),
              Text(
                '数据来源：AI 实时生成 · ${DateTime.now().toLocal()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pink[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}