import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_provider.dart';
import 'services/contacts_provider.dart';
import 'services/sos_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  
  // 恢复用户登录状态
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    try {
      final userId = int.parse(currentUser.id);
      SosService().currentUserId = userId;
      print('✅ 已恢复用户登录状态: userId=$userId');
    } catch (e) {
      print('⚠️ 恢复用户登录状态失败: $e');
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
      ],
      child: const NestWayApp(),
    ),
  );
}