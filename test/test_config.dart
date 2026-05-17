import 'package:supabase_flutter/supabase_flutter.dart';

class TestConfig {
  static const String supabaseUrl = 'https://fbnctnhjcjkbmmvcuqxh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhbmN0bmhqY2prYm1tdmN1cXhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDUwMzI0MTV9.L7m7UPuiMMo5L0Rqq5VBquJ0v0l0gFvCLyiDXxlCtE';

  static Future<void> initialize() async {
    print('Initializing Supabase test environment...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('Supabase test environment initialized');
  }
}
