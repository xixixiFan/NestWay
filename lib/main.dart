import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';  // 导入首页

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '栖途',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const HomePage(),   // 将首页作为入口
    );
  }
}