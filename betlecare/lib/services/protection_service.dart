import 'dart:convert';
import 'package:betlecare/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class ProtectionService {
  static final ProtectionService _instance = ProtectionService._internal();
  
  factory ProtectionService() {
    return _instance;
  }
  
  ProtectionService._internal();
  

final String todayUrl = ApiConfig.protectionTodayUrl;
  final String predictUrl = ApiConfig.protectionPredictUrl;
  final String consolidatedUrl = ApiConfig.protectionConsolidatedUrl;
  
  // check today's protection needs
  Future<Map<String, dynamic>> checkTodayProtectionNeeds(
    String location,
    double rainfall, 
    [double? minTemp, double? maxTemp]
  ) async {
    try {
    
      String formattedLocation = _formatLocation(location);
      
      print('🛡️ Protection API Request:');
      print('🛡️ URL: $todayUrl');
      print('🛡️ Location: "$location" → formatted to → "$formattedLocation"');
      print('🛡️ Rainfall: $rainfall mm');
      if (minTemp != null) print('🛡️ Min Temp: $minTemp°C');
      if (maxTemp != null) print('🛡️ Max Temp: $maxTemp°C');
      
      final Map<String, dynamic> requestBody = {
        'location': formattedLocation,
        'rainfall': rainfall,
      };
      
      if (minTemp != null) requestBody['min_temp'] = minTemp;
      if (maxTemp != null) requestBody['max_temp'] = maxTemp;
      
      final response = await http.post(
        Uri.parse(todayUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('🛡️ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to check protection needs: ${response.statusCode}');
      }
    } catch (e) {
      print('🛡️ Error checking protection needs: $e');
      rethrow;
    }
  }
  
  // Get 7 day protection forecast
  Future<Map<String, dynamic>> getProtectionForecast(
    String location,
    List<double> rainfallForecast, 
    [List<double>? minTempForecast, List<double>? maxTempForecast]
  ) async {
    try {
      
      String formattedLocation = _formatLocation(location);
      
      print('🛡️ Protection Forecast API Request:');
      print('🛡️ URL: $predictUrl');
      print('🛡️ Location: "$location" → formatted to → "$formattedLocation"');
      
      final Map<String, dynamic> requestBody = {
        'location': formattedLocation,
        'rainfall_forecast': rainfallForecast,
      };
      
    
      if (minTempForecast != null) requestBody['min_temp_forecast'] = minTempForecast;
      if (maxTempForecast != null) requestBody['max_temp_forecast'] = maxTempForecast;
      
      final response = await http.post(
        Uri.parse(predictUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('🛡️ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get protection forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('🛡️ Error getting protection forecast: $e');
      rethrow;
    }
  }
  
  // get consolidated protection forecast 
  Future<Map<String, dynamic>> getConsolidatedProtectionForecast(
    String location,
    List<double> rainfallForecast, 
    [List<double>? minTempForecast, List<double>? maxTempForecast]
  ) async {
    try {
    
      String formattedLocation = _formatLocation(location);
      
      print('🛡️ Consolidated Protection API Request:');
      print('🛡️ URL: $consolidatedUrl');
      print('🛡️ Location: "$location" → formatted to → "$formattedLocation"');
      
      final Map<String, dynamic> requestBody = {
        'location': formattedLocation,
        'rainfall_forecast': rainfallForecast,
      };
      
      if (minTempForecast != null) requestBody['min_temp_forecast'] = minTempForecast;
      if (maxTempForecast != null) requestBody['max_temp_forecast'] = maxTempForecast;
      
      final response = await http.post(
        Uri.parse(consolidatedUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('🛡️ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get consolidated protection forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('🛡️ Error getting consolidated protection forecast: $e');
      rethrow;
    }
  }
  
  // format location string to match API requirements (PUTTALAM or KURUNEGALA)
  String _formatLocation(String location) {
    String cleaned = location.trim();
    if (cleaned.contains('(') && cleaned.contains(')')) {
      int startIndex = cleaned.indexOf('(');
      int endIndex = cleaned.indexOf(')');
      if (startIndex < endIndex) {
        cleaned = cleaned.substring(startIndex + 1, endIndex).trim();
      }
    }

    cleaned = cleaned.toUpperCase().replaceAll(RegExp(r'[^\w\s]'), '');

    Map<String, String> districtMap = {
      'PUTTALAM': 'PUTTALAM',
      'KURUNEGALA': 'KURUNEGALA',
     
    };
    
    for (var key in districtMap.keys) {
      if (cleaned.contains(key)) {
        return districtMap[key]!;
      }
    }
    
    // Default to PUTTALAM if no match is found
    print('🛡️ Warning: Could not match location "$location" to a valid district. Defaulting to PUTTALAM.');
    return 'PUTTALAM';
  }
  

  String getProtectionTypeSinhala(int protectionType) {
    switch (protectionType) {
      case 1:
        return 'නියඟ ආරක්ෂණය';
      case 2:
        return 'අධික වැසි ආරක්ෂණය';
      default:
        return 'විශේෂ ආරක්ෂණයක් අවශ්‍ය නැත';
    }
  }
  

  Map<String, dynamic> getProtectionIconData(int protectionType) {
    switch (protectionType) {
      case 1: 
        return {
          'icon': 'water_drop',
          'color': 'orange',
        };
      case 2: 
        return {
          'icon': 'umbrella',
          'color': 'blue',
        };
      default:
        return {
          'icon': 'check_circle',
          'color': 'green',
        };
    }
  }
}