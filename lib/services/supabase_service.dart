import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _instance;

  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception('Supabase not initialized');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://fbnctnhjcjkbmmvcuqxh.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZibmN0bmhqY2prYm1tdmN1cXhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MTUwODQsImV4cCI6MjA5NDQ5MTA4NH0.YvPfjSifHCYpABVNU8XaGaAC6gsBun8eSGBa-qX7p04',
    );
    _instance = Supabase.instance.client;
  }
}
