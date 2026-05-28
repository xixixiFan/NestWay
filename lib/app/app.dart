import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../services/auth_provider.dart';
import '../pages/home/home_page.dart';
import '../pages/auth/login_page.dart';

class NestWayApp extends StatefulWidget {
  const NestWayApp({super.key});

  @override
  State<NestWayApp> createState() => _NestWayAppState();
}

class _NestWayAppState extends State<NestWayApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _waitForAuthInit();
  }

  Future<void> _waitForAuthInit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    int waitedMs = 0;
    while (authProvider.currentUser == null && waitedMs < 2000) {
      await Future.delayed(const Duration(milliseconds: 50));
      waitedMs += 50;
    }
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = ThemeData(
      primaryColor: const Color(0xFFFFE066),
      scaffoldBackgroundColor: const Color(0xFFF3F0FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
    );

    if (!_isInitialized) {
      return MaterialApp(
        title: 'NestWay',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'NestWay',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: authProvider.isLoggedIn ? HomePage() : LoginPage(),
      routes: AppRoutes.routes,
    );
  }
}