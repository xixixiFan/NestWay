import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/contacts_provider.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ContactsProvider(),
      child: const NestWayApp(),
    ),
  );
}