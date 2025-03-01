import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';
import 'package:betlecare/services/weather_services2.dart';  // Update path as needed

class MoreWeatherData extends StatefulWidget {
  final String selectedLocation;

  const MoreWeatherData({
    super.key, 
    required this.selectedLocation
  });

  @override
  State<MoreWeatherData> createState() => _MoreWeatherDataState();
}

class _MoreWeatherDataState extends State<MoreWeatherData> {
  final WeatherService _weatherService = WeatherService();
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
      final data = await _weatherService.fetchWeatherData(widget.selectedLocation);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error in detailed weather screen: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper methods to get weather data
  String getCurrentTemperature() {
    if (weatherData != null && weatherData!['current'] != null) {
      return '${weatherData!['current']['temperature_2m'].round()}°C';
    }
    return '—°C';
  }

  String getCurrentHumidity() {
    if (weatherData != null && weatherData!['current'] != null) {
      return '${weatherData!['current']['relative_humidity_2m'].round()}%';
    }
    return '—%';
  }

  String getCurrentRainfall() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      return '${rainfall.toStringAsFixed(1)}mm';
    }
    return '0.0mm';
  }

  String getTodayMinTemperature() {
    if (weatherData != null && weatherData!['daily'] != null) {
      return '${weatherData!['daily']['temperature_2m_min'][0].round()}°C';
    }
    return '—°C';
  }

  String getTodayMaxTemperature() {
    if (weatherData != null && weatherData!['daily'] != null) {
      return '${weatherData!['daily']['temperature_2m_max'][0].round()}°C';
    }
    return '—°C';
  }

  String getWeatherCondition() {
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      return getWeatherCodeDescription(code);
    }
    return 'නොදනී';
  }

  String getWindSpeed() {
    // Note: Open-Meteo doesn't provide wind speed in the basic API
    // You would need to add this parameter to your API call
    return '2kmh'; // Placeholder
  }

  String getWeatherCodeDescription(int code) {
    // Convert WMO weather codes to descriptions
    if (code < 3) return 'පැහැදිලි අහස';
    if (code < 50) return 'වළාකුළු සහිත';
    if (code < 70) return 'වැසි සහිත';
    if (code < 80) return 'හිම සහිත';
    return 'තද වැසි';
  }

  String getPageTitle() {
    // Display location name in title
    if (widget.selectedLocation == 'වත්මන් ස්ථානය (Current Location)' && 
        _weatherService.currentLocationName != 'වත්මන් ස්ථානය (Current Location)') {
      return '${_weatherService.currentLocationName} - අද දින කාලගුණය';
    }
    // Remove the English part from location name if present
    String displayName = widget.selectedLocation;
    if (displayName.contains('(')) {
      displayName = displayName.substring(0, displayName.indexOf('(')).trim();
    }
    return '$displayName - අද දින කාලගුණය';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE3F2FD), // Light blue background
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            getPageTitle(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Weather condition card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  getWeatherCondition(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getCurrentTemperature(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Top row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.water_drop,
                                  value: getCurrentRainfall(),
                                  label: 'වර්ෂාපතනය',
                                  iconColor: Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.wb_sunny,
                                  value: getCurrentTemperature(),
                                  label: 'උෂ්ණත්වය',
                                  iconColor: Colors.orange,
                                ),
                              ),
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.opacity,
                                  value: getCurrentHumidity(),
                                  label: 'ආර්ද්රතාවය',
                                  iconColor: Colors.lightBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Bottom row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.thermostat,
                                  value: getTodayMinTemperature(),
                                  label: 'අවම උෂ්ණත්වය',
                                  iconColor: Colors.lightBlue,
                                ),
                              ),
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.air,
                                  value: getWindSpeed(),
                                  label: 'සුළඟේ වේගය',
                                  iconColor: Colors.blueGrey,
                                ),
                              ),
                              Expanded(
                                child: _buildWeatherInfo(
                                  icon: Icons.thermostat,
                                  value: getTodayMaxTemperature(),
                                  label: 'උපරිම උෂ්ණත්වය',
                                  iconColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Additional tip based on weather
                          _buildWeatherAdviceCard(),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onTabChange: (index) {
          if (index != 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 40,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWeatherAdviceCard() {
    // Provide farming advice based on weather conditions
    String advice = 'සාමාන්‍ය කාලගුණ තත්වයක් පවතී.';
    IconData adviceIcon = Icons.check_circle;
    Color adviceColor = Colors.green;
    
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      
      if (code >= 70) {
        advice = 'අධික වැසි සහිත කාලගුණයක්. ගොවි කටයුතු කිරීමේදී පරිස්සම් වන්න.';
        adviceIcon = Icons.warning;
        adviceColor = Colors.red;
      } else if (code >= 50) {
        advice = 'වැසි සහිත කාලගුණයක්. බීජ රෝපණය කිරීමට සුදුසු කාලයකි.';
        adviceIcon = Icons.water_drop;
        adviceColor = Colors.blue;
      } else if (rainfall > 0.5) {
        advice = 'සුළු වැසි සහිත කාලගුණයක්. පැළ සිටවීමට සුදුසු කාලයකි.';
        adviceIcon = Icons.grass;
        adviceColor = Colors.green;
      } else {
        advice = 'පැහැදිලි කාලගුණයක්. ඵලදාව එකතු කිරීමට සුදුසු කාලයකි.';
        adviceIcon = Icons.wb_sunny;
        adviceColor = Colors.orange;
      }
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            adviceIcon,
            size: 40,
            color: adviceColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              advice,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}