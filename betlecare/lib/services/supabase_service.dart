import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For formatting the date
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

  // Fetch disease reports from the last 30 days
  Future<List<Map<String, dynamic>>> getDiseaseReportsFromDate() async {
    try {
      // Get the current date and subtract 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      // Format the date into a string compatible with Supabase's timestamp format
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(thirtyDaysAgo);

      // Query to fetch disease reports from the last 30 days
      final response = await _client
          .from('disease_reports')
          .select()
          .gte('created_at', formattedDate) // Filter by created_at column
          .order('created_at', ascending: false); // Order by creation date

      // Return the fetched records
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching disease reports: $e');
      return [];
    }
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
