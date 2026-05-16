import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const NestWayApp());
}