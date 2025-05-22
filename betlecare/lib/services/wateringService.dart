import 'dart:convert';
import 'package:betlecare/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'dart:developer' as developer;

class WateringService {
  static final WateringService _instance = WateringService._internal();
  final WeatherService _weatherService = WeatherService();
  
  final String baseUrl = ApiConfig.wateringCheckUrl;
  
  final bool _useHardcodedData = false;

  
  factory WateringService() {
    return _instance;
  }
  
  WateringService._internal();
  
  // calculate crop stage using plantedDate
  int _calculateCropStage(DateTime plantedDate) {
    final ageInDays = DateTime.now().difference(plantedDate).inDays;
    
    if (ageInDays < 30) return 1; 
    if (ageInDays < 60) return 3; 
    if (ageInDays < 90) return 5; 
    if (ageInDays < 180) return 7; 
    return 10; 
  }
  
  
  String _mapDistrictToBackendLocation(String district) {

    final districtMap = {
      'කුරුණෑගල': 'KURUNEGALA',
      'කුරුණෑගල (Kurunegala)': 'KURUNEGALA',
      'Kurunegala': 'KURUNEGALA',
      'පුත්තලම': 'PUTTALAM',
      'පුත්තලම (Puttalam)': 'PUTTALAM',
      'Puttalam': 'PUTTALAM',
    
    };
    
    return districtMap[district] ?? 'PUTTALAM'; 
  }
  
  // get watering recommendation for a betel bed
  Future<Map<String, dynamic>> getWateringRecommendation(BetelBed bed) async {
    
    developer.log('*** WATER RECOMMENDATION REQUEST ***', name: 'WateringService');
    developer.log('Bed ID: ${bed.id}', name: 'WateringService');
    developer.log('District: ${bed.district}', name: 'WateringService');
    developer.log('Betel Type: ${bed.betelType}', name: 'WateringService');
    developer.log('Area Size: ${bed.areaSize}', name: 'WateringService');
    developer.log('Age in Days: ${bed.ageInDays}', name: 'WateringService');
    developer.log('Crop Stage: ${_calculateCropStage(bed.plantedDate)}', name: 'WateringService');
    
    
    if (_useHardcodedData) {
      final cropStage = _calculateCropStage(bed.plantedDate);
      await Future.delayed(const Duration(milliseconds: 500));
      final result = _getHardcodedWateringRecommendation(bed.district, cropStage);
      developer.log('Using hardcoded data: $result', name: 'WateringService');
      return result;
    }
    
    try {
      // get weather data for the bed location
      final String locationKey = _getLocationKeyFromDistrict(bed.district);
      developer.log('Getting weather data for location: $locationKey', name: 'WateringService');
      
      final weatherData = await _weatherService.fetchWeatherData(locationKey);
      
      if (weatherData == null) {
        developer.log('Failed to fetch weather data', name: 'WateringService', error: 'Weather data is null');
        throw Exception('Failed to fetch weather data');
      }
      
      final currentWeather = weatherData['current'];
      final temperature = currentWeather['temperature_2m'];
      final rainfall = currentWeather['precipitation'] ?? 0.0;

      final List<Map<String, dynamic>> dailyForecast = _weatherService.prepareDailyForecast(weatherData);
      final todayForecast = dailyForecast.isNotEmpty ? dailyForecast[0] : null;
      
      final minTemp = todayForecast != null ? todayForecast['minTemp'] : (temperature - 5);
      final maxTemp = todayForecast != null ? todayForecast['maxTemp'] : (temperature + 5);
      
      
      final cropStage = _calculateCropStage(bed.plantedDate);
      
      // prepare request for backend API
      final requestBody = {
        'location': _mapDistrictToBackendLocation(bed.district),
        'rainfall': rainfall,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'crop_stage': cropStage,
        'month': DateTime.now().month
      };
      
      developer.log('API request body: $requestBody', name: 'WateringService');
      
    //make API reques
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        developer.log('API response: $result', name: 'WateringService');
        return result;
      } else {
        developer.log('API request failed: ${response.statusCode}', name: 'WateringService', error: response.body);
        throw Exception('Failed to get watering recommendation: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error getting watering recommendation: $e', name: 'WateringService', error: e);

      return {
        'watering_recommendation': 'Water once today',
        'water_amount': 4,
        'confidence': 50.0,
        'error': e.toString()
      };
    }
  }

  // map district to the locations used in weather service
  String _getLocationKeyFromDistrict(String district) {
    final districtMap = {
      'කුරුණෑගල': 'කුරුණෑගල (Kurunegala)',
      'කුරුණෑගල (Kurunegala)': 'කුරුණෑගල (Kurunegala)',
      'Kurunegala': 'කුරුණෑගල (Kurunegala)',
      'පුත්තලම': 'පුත්තලම (Puttalam)',
      'පුත්තලම (Puttalam)': 'පුත්තලම (Puttalam)',
      'Puttalam': 'පුත්තලම (Puttalam)',
      'අනමඩුව': 'අනමඩුව (Anamaduwa)',
    };
    
    return districtMap[district] ?? 'වත්මන් ස්ථානය (Current Location)';
  }
  


  
  //TODO remove this after testing ========== HARDCODED DATA FOR DEVELOPMENT ==========

  Map<String, dynamic> _getHardcodedWateringRecommendation(String district, int cropStage) {

    String recommendation;
    int waterAmount;
    double confidence;
    

    if (district.contains('Kurunegala') || district.contains('කුරුණෑගල')) {
      if (cropStage <= 3) {
 
        recommendation = 'Water twice today';
        waterAmount = 8;
        confidence = 85.0;
      } else {
        recommendation = 'Water once today';
        waterAmount = 5;
        confidence = 75.0;
      }
    } 

    else if (district.contains('Puttalam') || district.contains('පුත්තලම')) {
      if (cropStage < 7) {
        recommendation = 'Water twice today';
        waterAmount = 8;
        confidence = 90.0;
      } else {
        recommendation = 'Water once today';
        waterAmount = 5;
        confidence = 80.0;
      }
    }
    
    else {

      if (cropStage >= 7) {
        recommendation = 'No watering needed';
        waterAmount = 0;
        confidence = 65.0;
      } else {
        recommendation = 'Water once today';
        waterAmount = 4;
        confidence = 70.0;
      }
    }
    

    return {
      'location': _mapDistrictToBackendLocation(district),
      'watering_recommendation': recommendation,
      'water_amount': waterAmount,
      'confidence': confidence,
      'consecutive_dry_days': 3, 
      'probabilities': {
        'No watering': recommendation == 'No watering needed' ? 65.0 : 10.0,
        'Water once': recommendation == 'Water once today' ? 70.0 : 25.0,
        'Water twice': recommendation == 'Water twice today' ? 85.0 : 15.0,
      }
    };
  }
}