import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../services/weather_services2.dart';
import '../../widgets/weather/location_dropdown.dart';

class WeatherScreen2 extends StatefulWidget {
  const WeatherScreen2({super.key});

  @override
  State<WeatherScreen2> createState() => _WeatherScreen2State();
}

class _WeatherScreen2State extends State<WeatherScreen2> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  String selectedLocation = 'වත්මන් ස්ථානය (Current Location)';
  String locationDisplayName = 'වත්මන් ස්ථානය';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  List<Map<String, dynamic>> dailyForecast = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
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
          _animationController.forward();
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
      color: const Color.fromARGB(255, 246, 251, 255),
      child: Column(
        children: [
          _buildLocationDropdown(),
          _buildSelectedLocationDisplay(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : weatherData == null
                    ? _buildErrorState()
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildHeaderCard(),
                          ...dailyForecast.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> forecast = entry.value;
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0, 0.1 * (index + 1)),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      0.2 + (index * 0.1 > 0.6 ? 0.6 : index * 0.1), 
                                      0.7 + (index * 0.1 > 0.6 ? 0.6 : index * 0.1),
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                ),
                                child: _buildDailyForecastCard(
                                  forecast['day'],
                                  forecast['weather'],
                                  forecast['maxTemp'],
                                  forecast['minTemp'],
                                  forecast['rainfall'],
                                  forecast['humidity'],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'කාලගුණ තොරතුරු ලබා ගැනීමට නොහැකි විය',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchWeatherData,
            icon: const Icon(Icons.refresh),
            label: const Text('නැවත උත්සාහ කරන්න'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLocationDisplay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'සති අන්ත කාලගුණ අනාවැකිය',
                  style: TextStyle(
                    fontSize: 18, // Slightly reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ඔබගේ වගා සැලසුම් සඳහා ඉදිරි දින කිහිපයේ කාලගුණය',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastCard(String day, String weather, int maxTemp, int minTemp, dynamic rainfall, int humidity) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
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
                color: Colors.red.shade400,
              ),
              _buildWeatherInfo(
                icon: LineIcons.thermometerEmpty,
                label: 'අවම',
                value: '$minTemp°C',
                color: Colors.blue.shade400,
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
                color: Colors.blue.shade500,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTemperatureGraph(maxTemp, minTemp),
          
          // Add farming recommendation based on weather
          const SizedBox(height: 12),
          _buildFarmingRecommendation(weather, rainfall),
        ],
      ),
    );
  }

  Widget _buildFarmingRecommendation(String weather, dynamic rainfall) {
    String recommendation = '';
    IconData icon = Icons.check_circle;
    Color color = Colors.green;
    
    if (weather == 'rainy' || rainfall > 10) {
      recommendation = 'වැසි සහිත දිනයකි. පොහොර යෙදීම මඟහරින්න.';
      icon = Icons.water_drop;
      color = Colors.blue;
    } else if (weather == 'cloudy') {
      recommendation = 'මධ්‍යස්ත කාලගුණයක්. පැළ සිටුවීමට සුදුසුය.';
      icon = Icons.cloud;
      color = Colors.grey;
    } else {
      recommendation = 'හොඳ කාලගුණයක්. වගා කටයුතු සඳහා සුදුසුය.';
      icon = Icons.wb_sunny;
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
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

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(
        icon,
        size: 28,
        color: color,
      ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
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
    // Calculate the percentage of scale based on typical temperature range
    final minPossible = 0; // Assume 0°C is the lowest we care about
    final maxPossible = 40; // Assume 40°C is the highest we care about
    
    double minPercentage = (minTemp - minPossible) / (maxPossible - minPossible);
    double maxPercentage = (maxTemp - minPossible) / (maxPossible - minPossible);
    
    // Constrain to valid range
    minPercentage = minPercentage.clamp(0.0, 1.0);
    maxPercentage = maxPercentage.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'උෂ්ණත්ව පරාසය:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth * minPercentage,
                    right: constraints.maxWidth * (1 - maxPercentage),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300,
                            Colors.red.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${minTemp}°C',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${maxTemp}°C',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}