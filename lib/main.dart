import 'package:flutter/material.dart';
import 'pages/safety/destination_safety_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '栖途',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: DestinationSafetyPage(),
    );
  }
}