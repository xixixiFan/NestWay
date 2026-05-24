import 'package:flutter/material.dart';
import 'pages/profile/profile_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '栖途',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const ProfilePage(),   // 临时显示个人主页
    );
  }
}