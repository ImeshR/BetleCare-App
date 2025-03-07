import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/weather_services2.dart';

class WateringService {
  static final WateringService _instance = WateringService._internal();
  final WeatherService _weatherService = WeatherService();
// In watering_service.dart
// In your watering_service.dart
final String baseUrl = 'http://10.0.2.2:5000/api/watering';
  
  factory WateringService() {
    return _instance;
  }
  
  WateringService._internal();
  
  // Calculate crop stage based on plantedDate (1-10 scale)
  int _calculateCropStage(DateTime plantedDate) {
    final ageInDays = DateTime.now().difference(plantedDate).inDays;
    
    if (ageInDays < 30) return 1; // Establishing
    if (ageInDays < 60) return 3; // Young
    if (ageInDays < 90) return 5; // Early mature
    if (ageInDays < 180) return 7; // Mature
    return 10; // Fully mature
  }
  
  // Convert district name to the format expected by the backend
  String _mapDistrictToBackendLocation(String district) {
    // Map the Sinhala/English district names to the backend expected values
    // The backend API only accepts PUTTALAM or KURUNEGALA
    final districtMap = {
      'කුරුණෑගල': 'KURUNEGALA',
      'කුරුණෑගල (Kurunegala)': 'KURUNEGALA',
      'Kurunegala': 'KURUNEGALA',
      'පුත්තලම': 'PUTTALAM',
      'පුත්තලම (Puttalam)': 'PUTTALAM',
      'Puttalam': 'PUTTALAM',
      'අනුරාධපුර': 'KURUNEGALA', // Default to nearest location
      'කොළඹ': 'PUTTALAM',        // Default to nearest location
      'කළුතර': 'PUTTALAM',       // Default to nearest location
      'පානදුර': 'PUTTALAM',       // Default to nearest location
    };
    
    return districtMap[district] ?? 'PUTTALAM'; // Default to PUTTALAM if not found
  }
  
  // Get watering recommendation for a betel bed
  Future<Map<String, dynamic>> getWateringRecommendation(BetelBed bed) async {
    try {
      // First, get weather data for the bed's location
      final String locationKey = _getLocationKeyFromDistrict(bed.district);
      final weatherData = await _weatherService.fetchWeatherData(locationKey);
      
      if (weatherData == null) {
        throw Exception('Failed to fetch weather data');
      }
      
      // Extract today's weather info
      final currentWeather = weatherData['current'];
      final temperature = currentWeather['temperature_2m'];
      final rainfall = currentWeather['precipitation'] ?? 0.0;

      // Get daily forecast for today
      final List<Map<String, dynamic>> dailyForecast = _weatherService.prepareDailyForecast(weatherData);
      final todayForecast = dailyForecast.isNotEmpty ? dailyForecast[0] : null;
      
      final minTemp = todayForecast != null ? todayForecast['minTemp'] : (temperature - 5);
      final maxTemp = todayForecast != null ? todayForecast['maxTemp'] : (temperature + 5);
      
      // Calculate crop stage (1-10 scale based on age of plant)
      final cropStage = _calculateCropStage(bed.plantedDate);
      
      // Prepare request for backend API
      final requestBody = {
        'location': _mapDistrictToBackendLocation(bed.district),
        'rainfall': rainfall,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'crop_stage': cropStage,
        'month': DateTime.now().month
      };
      
      // Call backend API for watering recommendation
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get watering recommendation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting watering recommendation: $e');
      // Return a default recommendation if the backend is unavailable
      return {
        'watering_recommendation': 'Water once today',
        'water_amount': 4,
        'confidence': 50.0,
        'error': e.toString()
      };
    }
  }

  // Helper to map district to the locations used in weather service
  String _getLocationKeyFromDistrict(String district) {
    final districtMap = {
      'කුරුණෑගල': 'කුරුණෑගල (Kurunegala)',
      'කුරුණෑගල (Kurunegala)': 'කුරුණෑගල (Kurunegala)',
      'Kurunegala': 'කුරුණෑගල (Kurunegala)',
      'පුත්තලම': 'පුත්තලම (Puttalam)',
      'පුත්තලම (Puttalam)': 'පුත්තලම (Puttalam)',
      'Puttalam': 'පුත්තලම (Puttalam)',
      'අනමඩුව': 'අනමඩුව (Anamaduwa)',
      'කොළඹ': 'කොළඹ (Colombo)',
      'කළුතර': 'කළුතර (Kalutara)',
      'පානදුර': 'පානදුර (Panadura)',
      // Add more mappings as needed
    };
    
    return districtMap[district] ?? 'වත්මන් ස්ථානය (Current Location)';
  }
}