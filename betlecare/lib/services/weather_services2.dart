import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  // Weather API switch
  bool useOpenMeteo = false;
  
  // Weatherbit API key
  final String weatherbitApiKey = "884502715d6c45d6880cb8e0f20486a7";
  
  final Map<String, Map<String, double>> locations = {
    'වත්මන් ස්ථානය (Current Location)': {'lat': 0, 'lon': 0}, // Placeholder values, will be updated with actual location
    'කොළඹ (Colombo)': {'lat': 6.9271, 'lon': 79.8612},
    'කුරුණෑගල (Kurunegala)': {'lat': 7.4867, 'lon': 80.3647},
    'පුත්තලම (Puttalam)': {'lat': 8.0408, 'lon': 79.8358},
    'අනමඩුව (Anamaduwa)': {'lat': 8.0364, 'lon': 80.0105},
    'කළුතර (Kalutara)': {'lat': 6.5854, 'lon': 79.9607},
    'පානදුර (Panadura)': {'lat': 6.7130, 'lon': 79.9073},
  };

  // Map of city names for Weatherbit API
  final Map<String, String> cityNames = {
    'කොළඹ (Colombo)': 'Colombo',
    'කුරුණෑගල (Kurunegala)': 'Kurunegala',
    'පුත්තලම (Puttalam)': 'Puttalam',
    'අනමඩුව (Anamaduwa)': 'Anamaduwa',
    'කළුතර (Kalutara)': 'Kalutara',
    'පානදුර (Panadura)': 'Panadura',
  };

  // Added locationName to store the actual location name when using current location
  String currentLocationName = 'වත්මන් ස්ථානය (Current Location)';
  String currentCity = ''; // For Weatherbit API

  Future<Map<String, dynamic>?> fetchWeatherData(String location) async {
    if (useOpenMeteo) {
      return fetchOpenMeteoWeatherData(location);
    } else {
      return fetchWeatherbitWeatherData(location);
    }
  }

  // Original Open Meteo API implementation
  Future<Map<String, dynamic>?> fetchOpenMeteoWeatherData(String location) async {
    try {
      Map<String, double> coordinates;
      
      // Check if we need to get current location
      if (location == 'වත්මන් ස්ථානය (Current Location)') {
        Position position = await _getCurrentPosition();
        coordinates = {'lat': position.latitude, 'lon': position.longitude};
        // Update the stored coordinates for current location
        locations[location] = coordinates;
        
        // Get the name of the current location using reverse geocoding
        await _updateCurrentLocationName(position);
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

  // New Weatherbit API implementation
  Future<Map<String, dynamic>?> fetchWeatherbitWeatherData(String location) async {
    try {
      String cityName;
      
      // Check if we need to get current location
      if (location == 'වත්මන් ස්ථානය (Current Location)') {
        Position position = await _getCurrentPosition();
        
        // Get the name of the current location using reverse geocoding
        await _updateCurrentLocationName(position);
        cityName = currentCity;
      } else {
        cityName = cityNames[location] ?? 'Colombo'; // Default to Colombo if not found
      }
      
      final response = await http.get(Uri.parse(
          'https://api.weatherbit.io/v2.0/forecast/daily?city=${cityName},LK&key=$weatherbitApiKey&days=7'));

      if (response.statusCode == 200) {
        Map<String, dynamic> weatherbitData = json.decode(response.body);
        
        // Convert Weatherbit data format to match Open Meteo format for consistency
        return _convertWeatherbitToOpenMeteoFormat(weatherbitData);
      } else {
        print('Failed to load Weatherbit data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching Weatherbit data: $e');
      return null;
    }
  }
  
  // Method to convert Weatherbit response to Open Meteo format
  Map<String, dynamic> _convertWeatherbitToOpenMeteoFormat(Map<String, dynamic> weatherbitData) {
    // Get daily data
    List<dynamic> dailyData = weatherbitData['data'];
    
    // Prepare the conversion
    Map<String, dynamic> convertedData = {
      'daily': {
        'time': <String>[],
        'weather_code': <int>[],
        'temperature_2m_max': <double>[],
        'temperature_2m_min': <double>[],
        'precipitation_sum': <double>[],
        'precipitation_probability_max': <int>[],
        'relative_humidity_2m_max': <int>[],
      },
      'current': {
        'temperature_2m': dailyData[0]['temp'],
        'relative_humidity_2m': dailyData[0]['rh'],
        'precipitation': dailyData[0]['precip'],
        'weather_code': _convertWeatherbitCodeToOpenMeteoCode(dailyData[0]['weather']['code']),
      }
    };
    
    // Convert daily forecast data
    for (var day in dailyData) {
      convertedData['daily']['time'].add(day['datetime']);
      convertedData['daily']['weather_code'].add(_convertWeatherbitCodeToOpenMeteoCode(day['weather']['code']));
      convertedData['daily']['temperature_2m_max'].add(day['max_temp'].toDouble());
      convertedData['daily']['temperature_2m_min'].add(day['min_temp'].toDouble());
      convertedData['daily']['precipitation_sum'].add(day['precip'].toDouble());
      convertedData['daily']['precipitation_probability_max'].add(day['pop'] ?? 0); // Probability of precipitation
      convertedData['daily']['relative_humidity_2m_max'].add(day['rh'] ?? 0);
    }
    
    return convertedData;
  }
  
  // Convert Weatherbit code to OpenMeteo equivalent (approximate mapping)
  int _convertWeatherbitCodeToOpenMeteoCode(int code) {
    // Clear to partly cloudy
    if (code >= 800 && code <= 802) return 1; // Sunny to partly cloudy
    // Cloudy
    if (code >= 803 && code <= 804) return 45; // Cloudy
    // Rain
    if (code >= 500 && code <= 522) return 80; // Rain
    // Thunderstorm
    if (code >= 200 && code <= 233) return 95; // Thunderstorm
    // Snow
    if (code >= 600 && code <= 623) return 71; // Snow
    // Mist, fog
    if (code >= 700 && code <= 751) return 45; // Fog
    
    return 0; // Default clear
  }
  
  // Method to get current location name using reverse geocoding
  Future<void> _updateCurrentLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Update current location name with actual location
        String locality = place.locality ?? '';
        String subLocality = place.subLocality ?? '';
        String name = locality.isNotEmpty ? locality : subLocality;
        
        if (name.isNotEmpty) {
          currentLocationName = '$name (Current Location)';
          currentCity = name; // Save for Weatherbit API
        }
      }
    } catch (e) {
      print('Error getting location name: $e');
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
        'rainfall': weatherData['daily']['precipitation_sum'][i] ?? 0.0, // Explicitly treat as double
        'humidity': weatherData['daily']['relative_humidity_2m_max'][i].round(),
      });
    }
    
    return dailyForecast;
  }
}