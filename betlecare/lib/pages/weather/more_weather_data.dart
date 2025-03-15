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

class _MoreWeatherDataState extends State<MoreWeatherData> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
      final data = await _weatherService.fetchWeatherData(widget.selectedLocation);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
      _animationController.forward();
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

  Color getWeatherConditionColor() {
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      
      if (code < 3) return Colors.orange; // Clear sky
      if (code < 50) return Colors.blue.shade300; // Cloudy
      if (code < 70) return Colors.blue.shade600; // Rain
      return Colors.blue.shade900; // Heavy rain or snow
    }
    return Colors.grey;
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green.shade700),
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
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: fetchWeatherData,
                      color: Colors.green.shade700,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildTitleWithBack(),
                              const SizedBox(height: 20),
                              // Main weather card
                              _buildMainWeatherCard(),
                              const SizedBox(height: 24),
                              // Weather details section
                              _buildDetailsSections(),
                              const SizedBox(height: 24),
                              // Additional tip based on weather
                              _buildWeatherAdviceCard(),
                              const SizedBox(height: 24),
                              // Betel leaf specific recommendations
                              _buildBetelRecommendations(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4, // Weather tab
        onTabChange: (index) {
          if (index != 4) { // If not clicking the current tab
            // Create a replacement route to the MainPage with the correct tab index
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Pop all the way back to the main screen
              Navigator.of(context).popUntil((route) => route.isFirst);
              
              // Then push a replacement to force refresh the main page with the new index
              Navigator.of(context).pushReplacementNamed('/main', arguments: index);
            });
          } else {
            // If clicking the weather tab while already in weather section, just go back to main weather screen
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            getPageTitle(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
        gradient: LinearGradient(
          colors: [
            getWeatherConditionColor().withOpacity(0.7),
            getWeatherConditionColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: getWeatherConditionColor().withOpacity(0.3),
            blurRadius: 10,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildWeatherIcon(),
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
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTodayMaxTemperature(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTodayMinTemperature(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
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
              _buildVerticalDivider(),
              _buildMainCardDetail(
                icon: Icons.opacity,
                value: getCurrentHumidity(),
                label: 'ආර්ද්රතාවය',
              ),
              _buildVerticalDivider(),
              _buildMainCardDetail(
                icon: Icons.air,
                value: getWindSpeed(),
                label: 'සුළඟ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildMainCardDetail({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon() {
    IconData icon;
    
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      
      if (code < 3) {
        icon = Icons.wb_sunny;
      } else if (code < 50) {
        icon = Icons.cloud;
      } else if (code < 70) {
        icon = Icons.umbrella;
      } else {
        icon = Icons.ac_unit;
      }
    } else {
      icon = Icons.wb_sunny;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildDetailsSections() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'දවසේ විස්තර',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildWeatherInfo(
                  icon: Icons.thermostat,
                  value: getTodayMinTemperature(),
                  label: 'අවම උෂ්ණත්වය',
                  iconColor: Colors.blue,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'කාලගුණ උපදෙස්',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adviceColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  adviceIcon,
                  size: 24,
                  color: adviceColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getWeatherCondition(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: adviceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grass,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'බුලත් වගාව සඳහා උපදෙස්',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            title: 'වගා කටයුතු',
            description: _getBetelCultivationAdvice(),
            icon: Icons.agriculture,
          ),
          const Divider(height: 24),
          _buildRecommendationItem(
            title: 'පළිබෝධ කළමනාකරණය',
            description: _getPestManagementAdvice(),
            icon: Icons.bug_report,
          ),
          const Divider(height: 24),
          _buildRecommendationItem(
            title: 'ජල කළමනාකරණය',
            description: _getWaterManagementAdvice(),
            icon: Icons.water,
          ),
        ],
      ),
    );
  }

  String _getBetelCultivationAdvice() {
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      
      if (code >= 70 || rainfall > 10) {
        return 'දැඩි වැසි සහිත දිනයකි. බුලත් වගා බිම් තුල ජලය බැස යාමට සලස්වන්න. අද දින නව පැළ සිටුවීම අනුශාසා නොකරයි.';
      } else if (code >= 50 || rainfall > 1) {
        return 'මද වැසි සහිත දිනයකි. නව පැළ සිටුවීමට හොඳ දිනයකි. පාංශු තත්ත්වය පරීක්ෂා කරන්න.';
      } else {
        return 'පැහැදිලි කාලගුණයක්. පැළ වලට ජලය ලබා දෙන්න. උදෑසන හෝ සවස් කාලයේ ජලය ලබා දීම වඩාත් සුදුසුය.';
      }
    }
    return 'අද දිනට විශේෂ උපදෙසක් නොමැත.';
  }

  String _getPestManagementAdvice() {
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      int humidity = weatherData!['current']['relative_humidity_2m']?.round() ?? 0;
      
      if (humidity > 80 && code < 50) {
        return 'ඉහල ආර්ද්රතාවයක් පවතී. දිලීර ආසාදන ඇතිවීමේ අවදානම ඉහලයි. පරීක්ෂා කර බලන්න.';
      } else if (code >= 50) {
        return 'වැසි සහිත දිනයකි. ව්‍යාධි නාශක යෙදීම අනුශාසා නොකරයි.';
      } else {
        return 'ආරක්ෂිත පළිබෝධනාශක යෙදීමට සුදුසු දිනයකි. උදෑසන ජලය ඉසින්න.';
      }
    }
    return 'පළිබෝධ පාලනය සඳහා නියමිත කාල සටහන අනුගමනය කරන්න.';
  }

  String _getWaterManagementAdvice() {
    if (weatherData != null && weatherData!['current'] != null) {
      int code = weatherData!['current']['weather_code'] ?? 0;
      double rainfall = weatherData!['current']['precipitation'] ?? 0.0;
      double temp = weatherData!['current']['temperature_2m'] ?? 0.0;
      
      if (rainfall > 5) {
        return 'ප්‍රමාණවත් වර්ෂාපතනයක් ලැබී ඇත. අමතර ජලය ලබා දීම අවශ්‍ය නොවේ.';
      } else if (temp > 30) {
        return 'අධික උෂ්ණත්වයක් පවතී. දිනකට දෙවරක් ජලය ලබා දීම නිර්දේශ කරයි.';
      } else {
        return 'සාමාන්‍ය ජල සැපයුම පවත්වා ගන්න. පස විශාල ලෙස වියළී ඇත්නම් පමණක් ජලය ලබා දෙන්න.';
      }
    }
    return 'පස තත්ත්වය අනුව ජලය ලබා දීම තීරණය කරන්න.';
  }

  Widget _buildRecommendationItem({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}