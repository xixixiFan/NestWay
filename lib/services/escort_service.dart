import 'supabase_service.dart';
import 'sos_service.dart';
import 'location_service.dart';

/// 虚拟护送记录写入 Supabase escort_tasks 表
class EscortService {
  static final EscortService _instance = EscortService._internal();
  factory EscortService() => _instance;
  EscortService._internal();

  // 当前护送在数据库中的行 id（用于后续 update）
  int? _currentTaskId;
  int? get currentTaskId => _currentTaskId;

  /// 护送开始 — INSERT 一条记录，返回数据库生成的 id
  Future<int?> startEscort({
    required String escortId,       // 本地生成的唯一 id（毫秒时间戳字符串）
    required String destination,
    required int estimatedMinutes,
    required LocationPoint startPoint,
    required List<Map<String, dynamic>> contacts,
  }) async {
    final userId = SosService().currentUserId;
    if (userId == null) {
      print('[护送DB] ⚠️ 未登录，跳过写入');
      return null;
    }

    try {
      final contactNames = contacts.map((c) => c['name'] as String? ?? '').toList();

      final response = await SupabaseService.instance
          .from('escort_tasks')
          .insert({
            'user_id': userId,
            'escort_id': escortId,
            'destination': destination,
            'estimated_minutes': estimatedMinutes,
            'start_latitude': startPoint.latitude,
            'start_longitude': startPoint.longitude,
            'start_address': startPoint.address,
            'emergency_contacts': contactNames,
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      _currentTaskId = response['id'] as int?;
      print('[护送DB] ✅ 护送记录已创建: id=$_currentTaskId');
      return _currentTaskId;
    } catch (e) {
      print('[护送DB] ❌ 创建护送记录失败: $e');
      return null;
    }
  }

  /// 安全打卡 — UPDATE status = completed
  Future<bool> completeEscort({
    LocationPoint? endPoint,
  }) async {
    if (_currentTaskId == null) {
      print('[护送DB] ⚠️ 无当前护送记录，跳过 complete');
      return false;
    }

    try {
      await SupabaseService.instance
          .from('escort_tasks')
          .update({
            'status': 'completed',
            'end_latitude': endPoint?.latitude,
            'end_longitude': endPoint?.longitude,
            'end_address': endPoint?.address,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentTaskId!);

      print('[护送DB] ✅ 护送已完成: id=$_currentTaskId');
      _currentTaskId = null;
      return true;
    } catch (e) {
      print('[护送DB] ❌ 更新护送完成失败: $e');
      return false;
    }
  }

  /// 超时未打卡 — UPDATE status = timeout
  Future<bool> timeoutEscort({
    LocationPoint? lastLocation,
  }) async {
    if (_currentTaskId == null) {
      print('[护送DB] ⚠️ 无当前护送记录，跳过 timeout');
      return false;
    }

    try {
      await SupabaseService.instance
          .from('escort_tasks')
          .update({
            'status': 'timeout',
            'end_latitude': lastLocation?.latitude,
            'end_longitude': lastLocation?.longitude,
            'end_address': lastLocation?.address,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentTaskId!);

      print('[护送DB] ✅ 护送超时已记录: id=$_currentTaskId');
      _currentTaskId = null;
      return true;
    } catch (e) {
      print('[护送DB] ❌ 更新护送超时失败: $e');
      return false;
    }
  }

  /// 查询是否有未完成的护送（status = in_progress）
  Future<Map<String, dynamic>?> getActiveEscort() async {
    final userId = SosService().currentUserId;
    if (userId == null) return null;

    try {
      final response = await SupabaseService.instance
          .from('escort_tasks')
          .select()
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _currentTaskId = response['id'] as int?;
        print('[护送DB] 发现未完成护送: id=$_currentTaskId, destination=${response['destination']}');
      }
      return response;
    } catch (e) {
      print('[护送DB] ❌ 查询未完成护送失败: $e');
      return null;
    }
  }

  /// 查询当前用户的护送历史
  Future<List<Map<String, dynamic>>> getEscortHistory() async {
    final userId = SosService().currentUserId;
    if (userId == null) return [];

    try {
      final response = await SupabaseService.instance
          .from('escort_tasks')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[护送DB] ❌ 获取护送历史失败: $e');
      return [];
    }
  }

  void reset() {
    _currentTaskId = null;
  }
}
