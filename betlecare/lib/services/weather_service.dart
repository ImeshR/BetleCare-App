import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<Map<String, dynamic>> fetchWeatherData(double latitude,
      double longitude, DateTime startDate, DateTime endDate) async {
    final Uri url =
        Uri.parse('$_baseUrl?latitude=$latitude&longitude=$longitude'
            '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
            '&timezone=UTC'
            '&start_date=${startDate.toIso8601String().split('T')[0]}'
            '&end_date=${endDate.toIso8601String().split('T')[0]}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final daily = data['daily'];

      // Format the response as required
      return {
        'rainfall': daily['precipitation_sum'],
        'min_temp': daily['temperature_2m_min'],
        'max_temp': daily['temperature_2m_max'],
      };
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
