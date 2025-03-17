import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/fertilizing_service.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:intl/intl.dart';

class WeeklyFertilizingRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const WeeklyFertilizingRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);
  
  @override
  State<WeeklyFertilizingRecommendationWidget> createState() => _WeeklyFertilizingRecommendationWidgetState();
}

class _WeeklyFertilizingRecommendationWidgetState extends State<WeeklyFertilizingRecommendationWidget> {
  final FertilizingService _fertilizingService = FertilizingService();
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
  bool _isExpanded = false; // Add expand/collapse state
  Map<String, dynamic>? _todayRecommendation;
  Map<String, dynamic>? _fertilizePlan;
  String _errorMessage = '';
  bool _isAfterSixPm = false;
  
  @override
  void initState() {
    super.initState();
    _checkTime();
    _loadRecommendations();
  }
  
  void _checkTime() {
    final now = DateTime.now();
    _isAfterSixPm = now.hour >= 18;
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _checkTime(); // Update time check on refresh
    });
    
    try {
      // Get weather data to extract current rainfall
      final weatherData = await _weatherService.fetchWeatherData(widget.bed.district);
      
      if (weatherData == null) {
        setState(() {
          _errorMessage = 'Weather data not available';
          _isLoading = false;
        });
        return;
      }
      
      // Extract current rainfall from weather data
      final currentRainfall = weatherData['current']['precipitation'] as double? ?? 0.0;
      
      // Extract 7-day rainfall forecast
      List<double> rainfallForecast = [];
      if (weatherData['daily'] != null && weatherData['daily']['precipitation_sum'] != null) {
        final precipitationData = weatherData['daily']['precipitation_sum'];
        for (var i = 0; i < precipitationData.length && i < 7; i++) {
          rainfallForecast.add(precipitationData[i].toDouble());
        }
      }
      
      // Pad with zeros if we don't have 7 days
      while (rainfallForecast.length < 7) {
        rainfallForecast.add(0.0);
      }
      
      // Create fertilizer history from the bed's history
      final fertilizeHistory = widget.bed.fertilizeHistory.map((record) {
        return {
          'date': DateFormat('yyyy-MM-dd').format(record.date),
          'fertilizer': record.fertilizerType,
        };
      }).toList();
      
      // Get fertilizer plan
      final fertilizePlan = await _fertilizingService.getFertilizerPlan(
        widget.bed.district,
        rainfallForecast,
        fertilizeHistory,
      );
      
      // Only get today's recommendation if the date is in forecast or it's first time fertilizing
      final bool isFirstTime = fertilizePlan['recommendation']?['is_first_time'] ?? false;
      final bool dateInForecast = fertilizePlan['recommendation']?['date_in_forecast'] ?? false;
      
      Map<String, dynamic>? todayRecommendation;
      if (isFirstTime || dateInForecast) {
        todayRecommendation = await _fertilizingService.checkTodayFertilizingSuitability(
          widget.bed.district,
          currentRainfall,
        );
      }
      
      setState(() {
        _todayRecommendation = todayRecommendation;
        _fertilizePlan = fertilizePlan;
        
        // Get the is_after_six_pm value from the API response or use local check
        _isAfterSixPm = fertilizePlan['is_after_six_pm'] ?? 
                       (todayRecommendation != null ? todayRecommendation['is_after_six_pm'] : null) ?? 
                       _isAfterSixPm;
        
        _isLoading = false;
      });
    } catch (e) {
      print('🌱 Error in WeeklyFertilizingRecommendationWidget: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  bool _isDateWithinTwoWeeks(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      return difference >= 0 && difference <= 14;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_fertilizePlan == null) {
      return _buildUnavailableState();
    }
    
    return _buildDetailedRecommendationCard();
  }
  
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.grass, color: Colors.yellow.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'පොහොර යෙදීමේ නිර්දේශය ලබා ගනිමින්...',
              style: TextStyle(color: Colors.yellow.shade800),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.yellow.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'පොහොර නිර්දේශය ලබා ගත නොහැක',
                  style: TextStyle(color: Colors.yellow.shade800, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loadRecommendations,
              style: TextButton.styleFrom(
                foregroundColor: Colors.yellow.shade700,
              ),
              child: const Text('නැවත උත්සාහ කරන්න'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnavailableState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.grass, color: Colors.yellow.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'පොහොර යෙදීමේ නිර්දේශය ලබා ගත නොහැක',
              style: TextStyle(color: Colors.yellow.shade800),
            ),
          ),
          TextButton(
            onPressed: _loadRecommendations,
            style: TextButton.styleFrom(
              foregroundColor: Colors.yellow.shade700,
            ),
            child: const Text('නැවත උත්සාහ කරන්න'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedRecommendationCard() {
    // Always use yellow color theme for fertilizing
    final color = Colors.yellow.shade700;
    
    // Check if today's recommendation exists (only if date is in forecast or first time)
    final bool isFirstTime = _fertilizePlan!['recommendation']?['is_first_time'] ?? false;
    final bool dateInForecast = _fertilizePlan!['recommendation']?['date_in_forecast'] ?? false;
    
    // Get recommendation text based on time and suitability
    String statusText = '';
    IconData statusIcon = Icons.info;
    bool showTodayStatus = false;
    
    if (_todayRecommendation != null) {
      final isSuitable = _todayRecommendation!['suitable_for_fertilizing'] as bool? ?? false;
      final effectiveIsSuitable = _isAfterSixPm ? false : isSuitable;
      
      statusIcon = effectiveIsSuitable ? Icons.check_circle : Icons.cancel;
      
      if (_isAfterSixPm) {
        statusText = 'අද පොහොර යෙදීමට ප්‍රමාද වැඩිය';  // It's too late for fertilizing today
      } else {
        statusText = effectiveIsSuitable 
            ? 'පොහොර යෙදීමට සුදුසුයි' 
            : 'පොහොර යෙදීමට සුදුසු නැත';
      }
      
      showTodayStatus = true;
    }
    
    // Get detailed fertilizing plan
    String nextDate = '';
    String nextFertilizer = '';
    bool hasRecommendation = false;
    String firstTimeMessage = '';
    String message = '';
    
    // Get any forecast days that are suitable for fertilizing
    List<Map<String, dynamic>> suitableDays = [];
    
    if (_fertilizePlan != null && 
        _fertilizePlan!['recommendation'] != null) {
      
      final recommendation = _fertilizePlan!['recommendation'];
      
      // Check if this is the first time (no history)
      if (isFirstTime) {
        firstTimeMessage = _isAfterSixPm 
            ? 'පොහොර යෙදීම හෙටින් ආරම්භ කරන්න'  // Start fertilizing from tomorrow
            : 'පොහොර යෙදීම අදින් ආරම්භ කරන්න';   // Start fertilizing from today
      } 
      else if (recommendation['recommended_date'] != null && recommendation['next_fertilizer_sinhala'] != null) {
        // Not first time, show next date and fertilizer type
        nextDate = recommendation['recommended_date'];
        nextFertilizer = recommendation['next_fertilizer_sinhala'];
        hasRecommendation = true;
        
        // Get the message from recommendation
        if (recommendation['message'] != null) {
          message = recommendation['message'];
        }
      }
      
      // Only look for suitable days if date is in forecast
      if (dateInForecast && recommendation['weather_forecast'] != null && recommendation['weather_forecast'] is List) {
        final forecast = recommendation['weather_forecast'] as List;
        for (var day in forecast) {
          if (day is Map && day['suitable_for_fertilizing'] == true) {
            suitableDays.add(Map<String, dynamic>.from(day));
          }
        }
      }
    }
    
    // Check if next fertilizing date is within next 2 weeks (but after 7 days)
    bool showPrepareMessage = false;
    if (hasRecommendation && !dateInForecast && _isDateWithinTwoWeeks(nextDate)) {
      showPrepareMessage = true;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'පොහොර නිර්දේශය',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Today's status - only if date is in forecast or first time
          if (showTodayStatus)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          if (showTodayStatus)
            const SizedBox(height: 12),
          
          // First time message or next fertilizing plan - Always show this in collapsed or expanded mode
          if (isFirstTime) 
            _buildInfoSection(
              title: 'නිර්දේශය',
              content: firstTimeMessage,
              icon: Icons.new_releases,
              color: Colors.yellow.shade700
            )
          else if (hasRecommendation)
            _buildInfoSection(
              title: 'මීළඟ පොහොර යෙදීම',
              content: 'දිනය: $nextDate\nපොහොර වර්ගය: $nextFertilizer',
              icon: Icons.event,
              color: Colors.yellow.shade700
            ),
            
          // Preparation message if next fertilizing is within 2 weeks
          if (showPrepareMessage) ...[
            const SizedBox(height: 12),
            _buildInfoSection(
              title: 'සූදානම් වන්න',
              content: 'මීළඟ පොහොර යෙදීමට සූදානම් වන්න. ඔබට තව දින 14ක් ඇතුළත පොහොර යෙදීමට නියමිතයි.',
              icon: Icons.notification_important,
              color: Colors.yellow.shade700
            ),
          ],
            
          // Expanded content - only show when expanded
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            
            // Recommendation message if available
            if (message.isNotEmpty)
              _buildInfoSection(
                title: 'විස්තරය',
                content: message,
                icon: Icons.info_outline,
                color: Colors.yellow.shade700
              ),
              
            const SizedBox(height: 12),
            
            // List of suitable days in the next 7 days - only if date is in forecast
            if (dateInForecast && suitableDays.isNotEmpty) ...[
              Text(
                'ඉදිරි දින 7 තුළ පොහොර යෙදීමට සුදුසු දින:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade300, width: 1),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suitableDays.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final day = suitableDays[index];
                    final date = day['date'].toString();
                    final dayName = day['day_name_sinhala'] ?? day['day_name'];
                    final isBestDay = day['is_best_day'] == true;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          isBestDay 
                              ? Icon(Icons.star, color: Colors.yellow.shade700, size: 20)
                              : Icon(Icons.check_circle, color: Colors.yellow.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$dayName ($date)',
                              style: TextStyle(
                                fontWeight: isBestDay ? FontWeight.bold : FontWeight.normal,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (isBestDay)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.yellow.shade300, width: 1),
                              ),
                              child: Text(
                                'හොඳම දිනය',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}