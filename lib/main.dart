import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_provider.dart';
import 'services/contacts_provider.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('⚠️ Supabase 初始化失败（应用将继续以离线模式运行）: $e');
  }

  final authProvider = AuthProvider();
  await authProvider.init();

  print('✅ AuthProvider 已就绪');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
      ],
      child: const NestWayApp(),
    ),
  );
}