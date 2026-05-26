import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/demo_users.dart';
import 'sos_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isDemoMode = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?['id'] as int?;
  bool get isLoggedIn => _currentUser != null;
  bool get isDemoMode => _isDemoMode;

  Future<void> init() async {
    await _loadSavedLoginState();
  }

  Future<void> _loadSavedLoginState() async {
    try {
      print('🔧 正在加载保存的登录状态...');
      final prefs = await SharedPreferences.getInstance();

      // 优先检查演示模式
      final demoUserId = prefs.getInt('demo_user_id');
      if (demoUserId != null) {
        final user = demoUsers.firstWhere(
          (u) => u['id'] == demoUserId,
          orElse: () => demoUsers[0],
        );
        _currentUser = Map<String, dynamic>.from(user);
        _isDemoMode = true;
        SosService().currentUserId = demoUserId;
        print('✅ [演示] 登录状态已恢复: userId=$demoUserId, name=${user['name']}');
        notifyListeners();
        return;
      }

      // 检查 Supabase OTP 登录
      final otpUserId = prefs.getInt('supabase_user_id');
      if (otpUserId != null) {
        final name = prefs.getString('supabase_user_name') ?? '用户';
        final phone = prefs.getString('supabase_user_phone') ?? '';
        _currentUser = {
          'id': otpUserId,
          'name': name,
          'phone': phone,
        };
        _isDemoMode = false;
        SosService().currentUserId = otpUserId;
        print('✅ [OTP] 登录状态已恢复: userId=$otpUserId, name=$name, phone=$phone');
        notifyListeners();
        return;
      }

      print('🔧 没有找到保存的登录状态');
    } catch (e) {
      print('❌ 加载登录状态失败: $e');
    }
  }

  void loginAsDemoUser(int userId) {
    final user = demoUsers.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => demoUsers[0],
    );
    _currentUser = Map<String, dynamic>.from(user);
    _isDemoMode = true;
    SosService().currentUserId = userId;
    _saveDemoLoginState(userId);
    // 清除可能存在的 OTP 登录状态
    _clearOtpLoginState();
    notifyListeners();
  }

  void loginAsOtpUser(int userId, String name, String phone) {
    _currentUser = {
      'id': userId,
      'name': name,
      'phone': phone,
    };
    _isDemoMode = false;
    SosService().currentUserId = userId;
    _saveOtpLoginState(userId, name, phone);
    notifyListeners();
  }

  Future<void> _saveDemoLoginState(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('demo_user_id', userId);
    } catch (e) {
      print('保存演示登录状态失败: $e');
    }
  }

  Future<void> _saveOtpLoginState(int userId, String name, String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('supabase_user_id', userId);
      await prefs.setString('supabase_user_name', name);
      await prefs.setString('supabase_user_phone', phone);
    } catch (e) {
      print('保存OTP登录状态失败: $e');
    }
  }

  Future<void> _clearOtpLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('supabase_user_id');
      await prefs.remove('supabase_user_name');
      await prefs.remove('supabase_user_phone');
    } catch (e) {
      print('清除OTP登录状态失败: $e');
    }
  }

  void logout() async {
    _currentUser = null;
    _isDemoMode = false;
    SosService().currentUserId = null;
    await _clearLoginState();
    notifyListeners();
  }

  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('demo_user_id');
      await prefs.remove('supabase_user_id');
      await prefs.remove('supabase_user_name');
      await prefs.remove('supabase_user_phone');
    } catch (e) {
      print('清除登录状态失败: $e');
    }
  }
}
