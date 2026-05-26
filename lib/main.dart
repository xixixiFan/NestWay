import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_provider.dart';
import 'services/contacts_provider.dart';
import 'services/sos_service.dart';
import 'pages/main_page.dart';  // 导入全局底部导航栏主页

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
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '栖途',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const MainPage(),  // 使用全局底部导航栏主页
      routes: {
        // 如果还有其他路由，可以在此添加
      },
    );
  }
}