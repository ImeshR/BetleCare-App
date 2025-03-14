import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/weather_services2.dart';
import '../../widgets/weather/location_dropdown.dart';

class WeatherScreen2 extends StatefulWidget {
  const WeatherScreen2({super.key});

  @override
  State<WeatherScreen2> createState() => _WeatherScreen2State();
}

class _WeatherScreen2State extends State<WeatherScreen2> {
  final WeatherService _weatherService = WeatherService();
  String selectedLocation = 'වත්මන් ස්ථානය (Current Location)';
  String locationDisplayName = 'වත්මන් ස්ථානය';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  List<Map<String, dynamic>> dailyForecast = [];

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
      
      // Update location display name
      if (selectedLocation == 'වත්මන් ස්ථානය (Current Location)') {
        // Check if a current location name is available from the service
        if (_weatherService.currentLocationName != 'වත්මන් ස්ථානය (Current Location)') {
          // Extract the actual location name from the service's formatted string
          String fullName = _weatherService.currentLocationName;
          // The format is typically "LocationName (Current Location)"
          if (fullName.contains('(')) {
            locationDisplayName = fullName.substring(0, fullName.indexOf('(')).trim();
          } else {
            locationDisplayName = fullName;
          }
        } else {
          locationDisplayName = 'වත්මන් ස්ථානය';
        }
      } else {
        // For other locations, extract the Sinhala name without the English part
        if (selectedLocation.contains('(')) {
          locationDisplayName = selectedLocation.substring(0, selectedLocation.indexOf('(')).trim();
        } else {
          locationDisplayName = selectedLocation;
        }
      }
      
      setState(() {
        weatherData = data;
        if (data != null) {
          dailyForecast = _weatherService.prepareDailyForecast(data);
        }
      });
    } catch (e) {
      print('Error in weather screen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD),
      child: Column(
        children: [
          _buildLocationDropdown(),
          _buildSelectedLocationDisplay(),
          Expanded(
            child: ListView(
              children: [
                _buildHeaderCard(),
                if (!isLoading && weatherData != null)
                  ...dailyForecast.map((forecast) => _buildDailyForecastCard(
                        forecast['day'],
                        forecast['weather'],
                        forecast['maxTemp'],
                        forecast['minTemp'],
                        forecast['rainfall'],
                        forecast['humidity'],
                      )),
              ],
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (!isLoading && weatherData == null)
            const Center(
              child: Text('කාලගුණ තොරතුරු නොමැත - No weather data available'),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedLocationDisplay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            locationDisplayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return LocationDropdown(
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
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'සති අන්ත කාලගුණ අනාවැකිය',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastCard(String day, String weather, int maxTemp, int minTemp, dynamic rainfall, int humidity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildWeatherIcon(weather),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                icon: LineIcons.thermometer,
                label: 'උපරිම',
                value: '$maxTemp°C',
                color: Colors.red.shade300,
              ),
              _buildWeatherInfo(
                icon: LineIcons.thermometerEmpty,
                label: 'අවම',
                value: '$minTemp°C',
                color: Colors.blue.shade300,
              ),
              _buildWeatherInfo(
                icon: LineIcons.umbrella,
                label: 'වර්ෂාව',
                value: '${rainfall.toStringAsFixed(1)} mm',
                color: Colors.grey.shade600,
              ),
              _buildWeatherInfo(
                icon: LineIcons.water,
                label: 'ආර්ද්‍රතාව',
                value: '$humidity%',
                color: Colors.blue.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTemperatureGraph(maxTemp, minTemp),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String weather) {
    IconData icon;
    Color color;

    switch (weather) {
      case 'sunny':
        icon = LineIcons.sun;
        color = Colors.orange;
        break;
      case 'partly-cloudy':
        icon = LineIcons.cloud;
        color = Colors.grey.shade600;
        break;
      case 'cloudy':
        icon = LineIcons.cloudWithMoon;
        color = Colors.grey.shade600;
        break;
      case 'rainy':
        icon = LineIcons.cloudWithRain;
        color = Colors.blue.shade400;
        break;
      default:
        icon = LineIcons.sun;
        color = Colors.orange;
    }

    return Icon(
      icon,
      size: 32,
      color: color,
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 4),
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
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureGraph(int maxTemp, int minTemp) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade300,
            Colors.red.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}