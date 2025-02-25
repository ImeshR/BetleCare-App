import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final Map<String, Map<String, double>> locations = {
    'වත්මන් ස්ථානය (Current Location)': {'lat': 0, 'lon': 0}, // Placeholder values, will be updated with actual location
    'කොළඹ (Colombo)': {'lat': 6.9271, 'lon': 79.8612},
    'කුරුණෑගල (Kurunegala)': {'lat': 7.4867, 'lon': 80.3647},
    'පුත්තලම (Puttalam)': {'lat': 8.0408, 'lon': 79.8358},
    'අනමඩුව (Anamaduwa)': {'lat': 8.0364, 'lon': 80.0105},
    'කළුතර (Kalutara)': {'lat': 6.5854, 'lon': 79.9607},
    'පානදුර (Panadura)': {'lat': 6.7130, 'lon': 79.9073},
  };

  Future<Map<String, dynamic>?> fetchWeatherData(String location) async {
    try {
      Map<String, double> coordinates;
      
      // Check if we need to get current location
      if (location == 'වත්මන් ස්ථානය (Current Location)') {
        Position position = await _getCurrentPosition();
        coordinates = {'lat': position.latitude, 'lon': position.longitude};
        // Update the stored coordinates for current location
        locations[location] = coordinates;
      } else {
        coordinates = locations[location]!;
      }
      
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${coordinates['lat']}&longitude=${coordinates['lon']}&current=temperature_2m,relative_humidity_2m,precipitation,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,relative_humidity_2m_max&timezone=auto'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load weather data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }
  
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, handle accordingly
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle accordingly
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle accordingly
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  String getWeatherType(int code) {
    if (code < 3) return 'sunny';
    if (code < 50) return 'partly-cloudy';
    if (code < 70) return 'cloudy';
    return 'rainy';
  }

  List<Map<String, dynamic>> prepareDailyForecast(Map<String, dynamic>? weatherData) {
    if (weatherData == null) return [];

    final List<String> days = [
      'සඳුදා',
      'අඟහරුවාදා',
      'බදාදා',
      'බ්‍රහස්පතින්දා',
      'සිකුරාදා',
      'සෙනසුරාදා',
      'ඉරිදා',
    ];

    final now = DateTime.now();
    List<Map<String, dynamic>> dailyForecast = [];

    for (int i = 0; i < 7 && i < weatherData['daily']['time'].length; i++) {
      final forecastDate = DateTime.parse(weatherData['daily']['time'][i]);
      final dayIndex = (forecastDate.weekday - 1) % 7;
      
      dailyForecast.add({
        'day': days[dayIndex],
        'weather': getWeatherType(weatherData['daily']['weather_code'][i]),
        'maxTemp': weatherData['daily']['temperature_2m_max'][i].round(),
        'minTemp': weatherData['daily']['temperature_2m_min'][i].round(),
        'rainChance': weatherData['daily']['precipitation_probability_max'][i] ?? 0,
        'humidity': weatherData['daily']['relative_humidity_2m_max'][i].round(),
      });
    }
    
    return dailyForecast;
  }
}