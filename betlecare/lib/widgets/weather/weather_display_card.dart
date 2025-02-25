import 'package:betlecare/pages/weather/more_weather_data.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/services/weather_services2.dart';  // Make sure this path is correct
import 'location_dropdown.dart';  // Make sure this path is correct

class WeatherDisplayCard extends StatefulWidget {
  const WeatherDisplayCard({super.key});

  @override
  State<WeatherDisplayCard> createState() => _WeatherDisplayCardState();
}

class _WeatherDisplayCardState extends State<WeatherDisplayCard> {
  final WeatherService _weatherService = WeatherService();
  String selectedLocation = 'වත්මන් ස්ථානය (Current Location)';
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _weatherService.fetchWeatherData(selectedLocation);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error in weather display card: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get today's temperature from weather data
  String getCurrentTemperature() {
    if (weatherData != null && weatherData!['current'] != null) {
      return '${weatherData!['current']['temperature_2m'].round()}°C';
    }
    return '—°C';
  }

  // Get today's humidity from weather data
  String getCurrentHumidity() {
    if (weatherData != null && weatherData!['current'] != null) {
      return '${weatherData!['current']['relative_humidity_2m'].round()}%';
    }
    return '—%';
  }

  // Get today's rainfall from weather data
  String getCurrentRainfall() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      return '${rainfall.toStringAsFixed(1)}mm';
    }
    return '0.0mm';
  }

  // Get today's min temperature
  String getTodayMinTemperature() {
    if (weatherData != null && weatherData!['daily'] != null) {
      return '${weatherData!['daily']['temperature_2m_min'][0].round()}°C';
    }
    return '—°C';
  }

  // Get today's max temperature
  String getTodayMaxTemperature() {
    if (weatherData != null && weatherData!['daily'] != null) {
      return '${weatherData!['daily']['temperature_2m_max'][0].round()}°C';
    }
    return '—°C';
  }

  @override
  Widget build(BuildContext context) {
    // Get header title with location name
    String headerTitle = 'අද දින කාලගුණය';
    if (selectedLocation == 'වත්මන් ස්ථානය (Current Location)' && 
        _weatherService.currentLocationName != 'වත්මන් ස්ථානය (Current Location)') {
      headerTitle = '${_weatherService.currentLocationName} - අද දින කාලගුණය';
    } else if (selectedLocation != 'වත්මන් ස්ථානය (Current Location)') {
      // Show selected location name for non-current locations
      headerTitle = '$selectedLocation - අද දින කාලගුණය';
    }

    return Column(
      children: [
        // Add location dropdown
        LocationDropdown(
          selectedLocation: selectedLocation,
          locations: _weatherService.locations,
          onLocationChanged: (value) {
            if (value != null) {
              setState(() {
                selectedLocation = value;
              });
              fetchWeatherData();
            }
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(
                    headerTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherInfo(
                        icon: Icons.water_drop,
                        value: getCurrentRainfall(),
                        label: 'වර්ෂාපතනය',
                      ),
                      _buildWeatherInfo(
                        icon: Icons.wb_sunny,
                        value: getCurrentTemperature(),
                        label: 'උෂ්ණත්වය',
                      ),
                      _buildWeatherInfo(
                        icon: Icons.thermostat,
                        value: getCurrentHumidity(),
                        label: 'ආර්ද්රතාවය',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWeatherInfo(
                        icon: Icons.arrow_downward,
                        value: getTodayMinTemperature(),
                        label: 'අවම උෂ්ණත්වය',
                      ),
                      const SizedBox(width: 36),
                      _buildWeatherInfo(
                        icon: Icons.arrow_upward,
                        value: getTodayMaxTemperature(),
                        label: 'උපරිම උෂ්ණත්වය',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MoreWeatherData(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'තවත් විස්තර',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}