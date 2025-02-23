import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class SupabaseService {
  late final SupabaseClient _client;

  SupabaseService._();

  static Future<SupabaseService> init() async {
    final instance = SupabaseService._();
    final clientManager = await SupabaseClientManager.instance;
    instance._client = clientManager.client;
    return instance;
  }

  // Create
  Future<Map<String, dynamic>> create(
      String table, Map<String, dynamic> data) async {
    final response = await _client.from(table).insert(data).select().single();
    return response;
  }

  // Read
  Future<List<Map<String, dynamic>>> read(String table,
      {String? column, dynamic value}) async {
    var query = _client.from(table).select();
    if (column != null && value != null) {
      query = query.eq(column, value);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Update
  Future<Map<String, dynamic>> update(String table, Map<String, dynamic> data,
      String column, dynamic value) async {
    final response = await _client
        .from(table)
        .update(data)
        .eq(column, value)
        .select()
        .single();
    return response;
  }

  // Delete
  Future<void> delete(String table, String column, dynamic value) async {
    await _client.from(table).delete().eq(column, value);
  }
}
