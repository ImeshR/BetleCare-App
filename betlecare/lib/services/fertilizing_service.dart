import 'dart:convert';
import 'package:http/http.dart' as http;

class FertilizingService {
  static final FertilizingService _instance = FertilizingService._internal();
  
  factory FertilizingService() {
    return _instance;
  }
  
  FertilizingService._internal();
  
  // Direct URLs to the API endpoints
  final String todayUrl = 'http://192.168.43.160:5000/api/fertilizing/today';
  final String planUrl = 'http://192.168.43.160:5000/api/fertilizing/plan';
  
  // Check if today is suitable for fertilizing
  Future<Map<String, dynamic>> checkTodayFertilizingSuitability(String location, double rainfall) async {
    try {
      // Properly format the location string
      String formattedLocation = _formatLocation(location);
      
      print('🌱 Fertilizing API Request:');
      print('🌱 URL: $todayUrl');
      print('🌱 Location: "$location" → formatted to → "$formattedLocation"');
      print('🌱 Rainfall: $rainfall mm');
      
      final response = await http.post(
        Uri.parse(todayUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': formattedLocation,
          'rainfall': rainfall,
        }),
      );
      
      print('🌱 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to check fertilizing suitability: ${response.statusCode}');
      }
    } catch (e) {
      print('🌱 Error checking fertilizing suitability: $e');
      rethrow;
    }
  }
  
  // Get fertilizer planning recommendation
  Future<Map<String, dynamic>> getFertilizerPlan(String location, List<double> rainfallForecast, List<Map<String, String>> fertilizeHistory) async {
    try {
      // Properly format the location string
      String formattedLocation = _formatLocation(location);
      
      print('🌱 Fertilizer Plan API Request:');
      print('🌱 URL: $planUrl');
      print('🌱 Location: "$location" → formatted to → "$formattedLocation"');
      
      final response = await http.post(
        Uri.parse(planUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': formattedLocation,
          'rainfall_forecast': rainfallForecast,
          'fertilizer_history': fertilizeHistory,
        }),
      );
      
      print('🌱 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get fertilizer plan: ${response.statusCode}');
      }
    } catch (e) {
      print('🌱 Error getting fertilizer plan: $e');
      rethrow;
    }
  }
  
  // Format location string to match API requirements (PUTTALAM or KURUNEGALA)
  String _formatLocation(String location) {
    // Clean the location string
    String cleaned = location.trim();
    
    // Extract the English part if it has both Sinhala and English
    if (cleaned.contains('(') && cleaned.contains(')')) {
      int startIndex = cleaned.indexOf('(');
      int endIndex = cleaned.indexOf(')');
      if (startIndex < endIndex) {
        cleaned = cleaned.substring(startIndex + 1, endIndex).trim();
      }
    }
    
    // Convert to uppercase and remove any special characters
    cleaned = cleaned.toUpperCase().replaceAll(RegExp(r'[^\w\s]'), '');
    
    // Map district names to expected API values
    Map<String, String> districtMap = {
      'PUTTALAM': 'PUTTALAM',
      'KURUNEGALA': 'KURUNEGALA',
      // Add other mappings if needed
    };
    
    // Check if the location contains any of our valid district keywords
    for (var key in districtMap.keys) {
      if (cleaned.contains(key)) {
        return districtMap[key]!;
      }
    }
    
    // Default to PUTTALAM if no match is found
    print('🌱 Warning: Could not match location "$location" to a valid district. Defaulting to PUTTALAM.');
    return 'PUTTALAM';
  }
}