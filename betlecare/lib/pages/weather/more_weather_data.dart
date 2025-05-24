import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';
import 'package:betlecare/services/weather_services2.dart';

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
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      int code = weatherData!['current']['weather_code'] ?? 0;
      
      // Fix the logic based on actual precipitation amount
      if (rainfall >= 7.5) return 'තද වැසි';
      if (rainfall >= 2.5) return 'මද වැසි';
      if (rainfall >= 0.5) return 'සිහින් වැසි';
      if (code >= 50) return 'වළාකුළු සහිත';
      if (code >= 3) return 'අර්ධ වළාකුළු';
      return 'පැහැදිලි අහස';
    }
    return 'නොදනී';
  }

  Color getWeatherConditionColor() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      int code = weatherData!['current']['weather_code'] ?? 0;
      
      if (rainfall >= 7.5) return Colors.blue.shade700; // Heavy rain
      if (rainfall >= 2.5) return Colors.blue.shade500; // Moderate rain
      if (rainfall >= 0.5) return Colors.blue.shade300; // Light rain
      if (code >= 50) return Colors.blue.shade200; // Cloudy
      return Colors.orange.shade300; // Clear/sunny
    }
    return Colors.blue.shade100;
  }

IconData getWeatherIcon() {
  if (weatherData != null && weatherData!['current'] != null) {
    double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
    int code = weatherData!['current']['weather_code'] ?? 0;
    
    if (rainfall >= 2.5) return Icons.umbrella;
    if (rainfall >= 0.5) return Icons.grain;
    if (code >= 50) return Icons.cloud;
    if (code >= 3) return Icons.wb_cloudy; 
    return Icons.wb_sunny;
  }
  return Icons.wb_sunny;
}

  String getPageTitle() {
    if (widget.selectedLocation == 'වත්මන් ස්ථානය (Current Location)' && 
        _weatherService.currentLocationName != 'වත්මන් ස්ථානය (Current Location)') {
      return '${_weatherService.currentLocationName} - අද දින කාලගුණය';
    }
    String displayName = widget.selectedLocation;
    if (displayName.contains('(')) {
      displayName = displayName.substring(0, displayName.indexOf('(')).trim();
    }
    return '$displayName - අද දින කාලගුණය';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(
            child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue.shade500),
                      const SizedBox(height: 16),
                      Text(
                        'කාලගුණ තොරතුරු ලබාගනිමින්...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchWeatherData,
                  color: Colors.blue.shade500,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleWithBack(),
                          const SizedBox(height: 20),
                          _buildMainWeatherCard(),
                          const SizedBox(height: 20),
                          _buildDetailsSections(),
                          const SizedBox(height: 20),
                          _buildWeatherAdviceCard(),
                          const SizedBox(height: 20),
                          _buildBetelRecommendations(),
                          const SizedBox(height: 40),
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed('/main', arguments: index);
            });
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildTitleWithBack() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            getPageTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getWeatherConditionColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getWeatherCondition(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  getWeatherIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getCurrentTemperature(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        getTodayMaxTemperature(),
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        getTodayMinTemperature(),
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMainCardDetail(
                icon: Icons.water_drop,
                value: getCurrentRainfall(),
                label: 'වර්ෂාපතනය',
              ),
              Container(height: 30, width: 1, color: Colors.white.withOpacity(0.3)),
              _buildMainCardDetail(
                icon: Icons.opacity,
                value: getCurrentHumidity(),
                label: 'ආර්ද්රතාවය',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardDetail({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSections() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'දවසේ විස්තර',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                icon: Icons.thermostat,
                value: getTodayMinTemperature(),
                label: 'අවම උෂ්ණත්වය',
                iconColor: Colors.blue,
              ),
              _buildWeatherInfo(
                icon: Icons.thermostat,
                value: getTodayMaxTemperature(),
                label: 'උපරිම උෂ්ණත්වය',
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
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
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeatherAdviceCard() {
    String advice = _getWeatherAdvice();
    IconData adviceIcon = _getAdviceIcon();
    Color adviceColor = _getAdviceColor();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'කාලගුණ උපදෙස්',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: adviceColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(adviceIcon, size: 20, color: adviceColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  advice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBetelRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'බුලත් වගාව සඳහා උපදෙස්',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getBetelAdvice(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherAdvice() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      
      if (rainfall >= 7.5) {
        return 'අධික වැසි සහිත කාලගුණයක්. ගොවි කටයුතු කිරීමේදී පරිස්සම් වන්න.';
      } else if (rainfall >= 2.5) {
        return 'මද වැසි සහිත කාලගුණයක්. බීජ රෝපණය කිරීමට සුදුසු කාලයකි.';
      } else if (rainfall >= 0.5) {
        return 'සුළු වැසි සහිත කාලගුණයක්. පැළ සිටවීමට සුදුසු කාලයකි.';
      } else {
        return 'පැහැදිලි කාලගුණයක්. ඵලදාව එකතු කිරීමට සුදුසු කාලයකි.';
      }
    }
    return 'සාමාන්‍ය කාලගුණ තත්වයක් පවතී.';
  }

  IconData _getAdviceIcon() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      
      if (rainfall >= 7.5) return Icons.warning;
      if (rainfall >= 2.5) return Icons.water_drop;
      if (rainfall >= 0.5) return Icons.grass;
      return Icons.wb_sunny;
    }
    return Icons.check_circle;
  }

  Color _getAdviceColor() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      
      if (rainfall >= 7.5) return Colors.red;
      if (rainfall >= 2.5) return Colors.blue;
      if (rainfall >= 0.5) return Colors.green;
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getBetelAdvice() {
    if (weatherData != null && weatherData!['current'] != null) {
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      int humidity = weatherData!['current']['relative_humidity_2m']?.round() ?? 0;
      double temp = weatherData!['current']['temperature_2m'] ?? 0.0;
      
      if (rainfall > 5) {
        return 'ප්‍රමාණවත් වර්ෂාපතනයක් ලැබී ඇත. අමතර ජලය ලබා දීම අවශ්‍ය නොවේ. ජලය බැස යාමට සලස්වන්න.';
      } else if (humidity > 80) {
        return 'ඉහල ආර්ද්රතාවයක් පවතී. දිලීර ආසාදන ඇතිවීමේ අවදානම ඉහලයි. පරීක්ෂා කර බලන්න.';
      } else if (temp > 30) {
        return 'අධික උෂ්ණත්වයක් පවතී. දිනකට දෙවරක් ජලය ලබා දීම නිර්දේශ කරයි.';
      } else {
        return 'සාමාන්‍ය ජල සැපයුම පවත්වා ගන්න. පස තත්ත්වය අනුව ජලය ලබා දීම තීරණය කරන්න.';
      }
    }
    return 'පස තත්ත්වය අනුව ජලය ලබා දීම තීරණය කරන්න.';
  }
}