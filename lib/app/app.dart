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
      primaryColor: const Color(0xFFFFE066),
      scaffoldBackgroundColor: const Color(0xFFF3F0FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}