import 'package:betlecare/pages/weather/more_weather_data.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'location_dropdown.dart';

class WeatherDisplayCard extends StatefulWidget {
  const WeatherDisplayCard({super.key});

  @override
  State<WeatherDisplayCard> createState() => _WeatherDisplayCardState();
}

class _WeatherDisplayCardState extends State<WeatherDisplayCard> 
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  String selectedLocation = 'වත්මන් ස්ථානය (Current Location)';
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    fetchWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
    } catch (e) {
      print('Error in weather display card: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    String headerTitle = 'අද දින කාලගුණය';
    if (selectedLocation == 'වත්මන් ස්ථානය (Current Location)' && 
        _weatherService.currentLocationName != 'වත්මන් ස්ථානය (Current Location)') {
      headerTitle = '${_weatherService.currentLocationName} - අද දින කාලගුණය';
    } else if (selectedLocation != 'වත්මන් ස්ථානය (Current Location)') {
      headerTitle = '$selectedLocation - අද දින කාලගුණය';
    }

    return Column(
      children: [
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
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: isLoading 
              ? SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade400,
                      ),
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          headerTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildWeatherInfo(
                            icon: Icons.water_drop,
                            value: getCurrentRainfall(),
                            label: 'වර්ෂාපතනය',
                            color: Colors.blue.shade400,
                          ),
                          _buildWeatherInfo(
                            icon: Icons.wb_sunny,
                            value: getCurrentTemperature(),
                            label: 'උෂ්ණත්වය',
                            color: Colors.orange.shade400,
                          ),
                          _buildWeatherInfo(
                            icon: Icons.opacity,
                            value: getCurrentHumidity(),
                            label: 'ආර්ද්රතාවය',
                            color: Colors.teal.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTemperatureRange(
                            icon: Icons.arrow_downward,
                            value: getTodayMinTemperature(),
                            label: 'අවම',
                            color: Colors.blue.shade400,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.grey.shade300,
                          ),
                          _buildTemperatureRange(
                            icon: Icons.arrow_upward,
                            value: getTodayMaxTemperature(),
                            label: 'උපරිම',
                            color: Colors.red.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoreWeatherData(
                                selectedLocation: selectedLocation,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'තවත් විස්තර',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 90,
        maxWidth: 110,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureRange({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}