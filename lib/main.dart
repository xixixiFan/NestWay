import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_provider.dart';
import 'services/contacts_provider.dart';
import 'services/sos_service.dart';
import 'app/app.dart';  // 导入正确的入口文件

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  
  // 初始化 AuthProvider 并加载保存的登录状态
  final authProvider = AuthProvider();
  await authProvider.init();
  
  print('✅ Supabase 初始化完成');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
      ],
      child: const NestWayApp(),  // 使用正确的入口
    ),
  );
}
