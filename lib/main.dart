import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/auth_provider.dart';
import 'services/contacts_provider.dart';
import 'services/sos_service.dart';
import 'pages/escort/escort_page.dart';
import 'pages/safety/destination_safety_page.dart';
import 'pages/sos/sos_page.dart';
import 'pages/profile/profile_page.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

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
    // 将 MainPage 作为首页，保留所有命名路由
    final routeTable = Map<String, WidgetBuilder>.from(AppRoutes.routes);
    routeTable[AppRoutes.home] = (context) => const MainPage();

    return MaterialApp(
      title: '栖途',
      theme: ThemeData(primarySwatch: Colors.pink),
      initialRoute: AppRoutes.login,
      routes: routeTable,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 0:虚拟护送, 1:预警, 2:SOS, 3:我的

  final List<Widget> _pages = [
    const EscortPage(),                     // 虚拟护送（需要实现或临时占位）
    const DestinationSafetyPage(cityName: '杭州'), // 预警（默认城市可改）
    const SosPage(),                        // SOS（队友实现）
    const ProfilePage(),                    // 我的
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '虚拟护送',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            label: '预警',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sos),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}