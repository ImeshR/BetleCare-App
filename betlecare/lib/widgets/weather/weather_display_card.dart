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
      duration: const Duration(milliseconds: 800),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: isLoading 
                ? SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
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
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade100.withOpacity(0.5),
                                Colors.blue.shade200.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            headerTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                              letterSpacing: 0.5,
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
                              gradientColors: [
                                Colors.blue.shade300,
                                Colors.blue.shade500,
                              ],
                            ),
                            _buildWeatherInfo(
                              icon: Icons.wb_sunny,
                              value: getCurrentTemperature(),
                              label: 'උෂ්ණත්වය',
                              gradientColors: [
                                Colors.orange.shade300,
                                Colors.orange.shade500,
                              ],
                            ),
                            _buildWeatherInfo(
                              icon: Icons.opacity,
                              value: getCurrentHumidity(),
                              label: 'ආර්ද්රතාවය',
                              gradientColors: [
                                Colors.teal.shade300,
                                Colors.teal.shade500,
                              ],
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
                              height: 40,
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.grey.shade300.withOpacity(0.1),
                                    Colors.grey.shade300,
                                    Colors.grey.shade300.withOpacity(0.1),
                                  ],
                                ),
                              ),
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
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade500,
                                Colors.blue.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade400.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
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
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 36,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'තවත් විස්තර',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
    required List<Color> gradientColors,
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withOpacity(0.2),
                  gradientColors[1].withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gradientColors[1].withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[1].withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: gradientColors[1],
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
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