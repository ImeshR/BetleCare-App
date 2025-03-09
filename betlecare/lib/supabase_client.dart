import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static SupabaseClientManager? _instance;
  late final SupabaseClient _supabaseClient;

  SupabaseClientManager._();

  static Future<SupabaseClientManager> get instance async {
    if (_instance == null) {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      _instance = SupabaseClientManager._();
      _instance!._supabaseClient = Supabase.instance.client;
    }
    return _instance!;
  }

  SupabaseClient get client => _supabaseClient;
}
