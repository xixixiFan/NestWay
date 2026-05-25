import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NestWayApp extends StatelessWidget {
  const NestWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NestWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 禁用 Google Fonts，使用系统默认字体
        fontFamily: null,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: ''),
          bodyMedium: TextStyle(fontFamily: ''),
          bodySmall: TextStyle(fontFamily: ''),
          titleLarge: TextStyle(fontFamily: ''),
          titleMedium: TextStyle(fontFamily: ''),
          titleSmall: TextStyle(fontFamily: ''),
          labelLarge: TextStyle(fontFamily: ''),
          labelMedium: TextStyle(fontFamily: ''),
          labelSmall: TextStyle(fontFamily: ''),
        ),
        primaryColor: const Color(0xFFFFE066),
        scaffoldBackgroundColor: const Color(0xFFF3F0FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}