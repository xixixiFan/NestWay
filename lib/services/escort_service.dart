import 'supabase_service.dart';
import 'sos_service.dart';
import 'location_service.dart';

/// 虚拟护送记录写入 Supabase escort_tasks 表
/// 表结构：id, user_id, start_location, end_location, estimated_duration,
///         status(active/completed/timeout), started_at, completed_at,
///         last_location_lat, last_location_lng, created_at
class EscortService {
  static final EscortService _instance = EscortService._internal();
  factory EscortService() => _instance;
  EscortService._internal();

  int? _currentTaskId;
  int? get currentTaskId => _currentTaskId;

  /// 护送开始 — INSERT，status = active
  Future<int?> startEscort({
    required String destination,
    required int estimatedMinutes,
    required LocationPoint startPoint,
  }) async {
    final userId = SosService().currentUserId;
    if (userId == null) {
      print('[护送DB] ⚠️ 未登录，跳过写入');
      return null;
    }

    try {
      final response = await SupabaseService.instance
          .from('escort_tasks')
          .insert({
            'user_id': userId,
            'start_location': startPoint.address,
            'end_location': destination,
            'estimated_duration': estimatedMinutes,
            'status': 'active',
            'started_at': DateTime.now().toIso8601String(),
            'last_location_lat': startPoint.latitude,
            'last_location_lng': startPoint.longitude,
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

  /// 完成护送
  Future<void> completeEscort({LocationPoint? lastLocation}) async {
    if (_currentTaskId == null) return;

    try {
      final taskId = _currentTaskId!;
      final updateData = <String, dynamic>{
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      };

      if (lastLocation != null) {
        updateData['last_known_lat'] = lastLocation.latitude;
        updateData['last_known_lng'] = lastLocation.longitude;
        updateData['last_known_address'] = lastLocation.address;
      }

      await SupabaseService.instance
          .from('escort_tasks')
          .update(updateData)
          .eq('id', taskId);

      print('[护送DB] ✅ 护送已完成: id=$taskId');
      _currentTaskId = null;
    } catch (e) {
      print('[护送DB] ❌ 完成护送失败: $e');
    }
  }

  /// 超时未打卡 — UPDATE status = timeout
  Future<bool> timeoutEscort({LocationPoint? lastLocation}) async {
    if (_currentTaskId == null) {
      print('[护送DB] ⚠️ 无当前护送记录，跳过 timeout');
      return false;
    }

    try {
      final taskId = _currentTaskId!;
      await SupabaseService.instance
          .from('escort_tasks')
          .update({
            'status': 'timeout',
            'completed_at': DateTime.now().toIso8601String(),
            if (lastLocation != null) 'last_location_lat': lastLocation.latitude,
            if (lastLocation != null) 'last_location_lng': lastLocation.longitude,
          })
          .eq('id', taskId);

      print('[护送DB] ✅ 护送超时已记录: id=$taskId');
      _currentTaskId = null;
      return true;
    } catch (e) {
      print('[护送DB] ❌ 更新护送超时失败: $e');
      return false;
    }
  }

  /// 放弃当前未完成的护送（改为 timeout），用于新建护送前清理旧记录
  Future<void> abandonActiveEscort() async {
    final userId = SosService().currentUserId;
    if (userId == null) return;

    try {
      await SupabaseService.instance
          .from('escort_tasks')
          .update({
            'status': 'canceled',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');

      _currentTaskId = null;
      print('[护送DB] ✅ 旧护送记录已标记为 canceled');
    } catch (e) {
      print('[护送DB] ❌ 放弃旧护送记录失败: $e');
    }
  }

  /// 查询是否有未完成的护送（status = active）
  Future<Map<String, dynamic>?> getActiveEscort() async {
    final userId = SosService().currentUserId;
    if (userId == null) return null;

    try {
      final response = await SupabaseService.instance
          .from('escort_tasks')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // 检查是否已经超时
        final startedAt = DateTime.tryParse(response['started_at'] as String? ?? '');
        final estimatedDuration = response['estimated_duration'] as int? ?? 0;
        
        if (startedAt != null && response['status'] == 'active') {
          final now = DateTime.now();
          final deadline = startedAt.add(Duration(minutes: estimatedDuration));
          
          if (now.isAfter(deadline)) {
            // 已经超时，自动标记为 timeout
            print('[护送DB] 发现过期护送，自动标记为 timeout');
            final taskId = response['id'] as int;
            await SupabaseService.instance
                .from('escort_tasks')
                .update({
                  'status': 'timeout',
                  'completed_at': DateTime.now().toIso8601String(),
                })
                .eq('id', taskId);
            return null;
          }
        }
        
        _currentTaskId = response['id'] as int?;
        print('[护送DB] 发现未完成护送: id=$_currentTaskId, destination=${response['end_location']}, status=${response['status']}');
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

  /// 标记当前护送为 SOS 状态
  Future<void> markAsSos({LocationPoint? lastLocation}) async {
    if (_currentTaskId == null) {
      print('[护送DB] ❌ 没有正在进行的护送任务，无法标记为 SOS');
      return;
    }

    try {
      final taskId = _currentTaskId!;
      final updateData = <String, dynamic>{
        'status': 'sos',
      };

      if (lastLocation != null) {
        updateData['last_known_lat'] = lastLocation.latitude;
        updateData['last_known_lng'] = lastLocation.longitude;
        updateData['last_known_address'] = lastLocation.address;
      }

      await SupabaseService.instance
          .from('escort_tasks')
          .update(updateData)
          .eq('id', taskId);

      print('[护送DB] ✅ 护送已标记为 SOS: id=$taskId');
    } catch (e) {
      print('[护送DB] ❌ 标记 SOS 失败: $e');
    }
  }

  /// 从 SOS 状态恢复护送
  Future<void> resumeFromSos() async {
    if (_currentTaskId == null) return;

    try {
      final taskId = _currentTaskId!;
      await SupabaseService.instance
          .from('escort_tasks')
          .update({'status': 'active'})
          .eq('id', taskId);

      print('[护送DB] ✅ 护送已从 SOS 恢复: id=$taskId');
    } catch (e) {
      print('[护送DB] ❌ 恢复护送失败: $e');
    }
  }

  void reset() {
    _currentTaskId = null;
  }
}
