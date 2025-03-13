import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/fertilizing_service.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:intl/intl.dart';

class FertilizingRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const FertilizingRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);
  
  @override
  State<FertilizingRecommendationWidget> createState() => _FertilizingRecommendationWidgetState();
}

class _FertilizingRecommendationWidgetState extends State<FertilizingRecommendationWidget> {
  final FertilizingService _fertilizingService = FertilizingService();
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
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
      
      // Get today's fertilizing recommendation
      final todayRecommendation = await _fertilizingService.checkTodayFertilizingSuitability(
        widget.bed.district,
        currentRainfall,
      );
      
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
      
      setState(() {
        _todayRecommendation = todayRecommendation;
        _fertilizePlan = fertilizePlan;
        
        // Get the is_after_six_pm value from the API response or use local check
        _isAfterSixPm = fertilizePlan['is_after_six_pm'] ?? 
                         todayRecommendation['is_after_six_pm'] ?? 
                         _isAfterSixPm;
        
        _isLoading = false;
      });
    } catch (e) {
      print('🌱 Error in FertilizingRecommendationWidget: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    
    if (_todayRecommendation == null) {
      return _buildUnavailableState();
    }
    
    return _buildRecommendationCard();
  }
  
  Widget _buildLoadingState() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.grass, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'පොහොර යෙදීමේ නිර්දේශය ලබා ගනිමින්...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'පොහොර නිර්දේශය ලබා ගත නොහැක',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loadRecommendations,
                child: const Text('නැවත උත්සාහ කරන්න'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnavailableState() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.grass, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'පොහොර යෙදීමේ නිර්දේශය ලබා ගත නොහැක',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: _loadRecommendations,
              child: const Text('නැවත උත්සාහ කරන්න'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationCard() {
    // Get values from API responses with fallbacks
    final isSuitable = _todayRecommendation!['suitable_for_fertilizing'] as bool;
    final isAfterSixPm = _isAfterSixPm;
    
    // If it's after 6 PM, adjust the recommendation as needed
    final effectiveIsSuitable = isAfterSixPm ? false : isSuitable;
    
    final color = effectiveIsSuitable ? Colors.green.shade700 : Colors.orange.shade700;
    final icon = effectiveIsSuitable ? Icons.check_circle : Icons.cancel;
    
    // Get recommendation text based on time and suitability
    String statusText;
    if (isAfterSixPm) {
      statusText = 'අද පොහොර යෙදීමට ප්‍රමාද වැඩිය';  // It's too late for fertilizing today
    } else {
      statusText = effectiveIsSuitable 
          ? 'පොහොර යෙදීමට සුදුසුයි' 
          : 'පොහොර යෙදීමට සුදුසු නැත';
    }
    
    // Get next recommended date and fertilizer type from plan if available
    String nextDate = '';
    String nextFertilizer = '';
    String nextFertilizerSinhala = '';
    bool hasRecommendation = false;
    bool isFirstTime = false;
    String firstTimeMessage = '';
    
    if (_fertilizePlan != null && _fertilizePlan!['recommendation'] != null) {
      final recommendation = _fertilizePlan!['recommendation'];
      
      // Check if this is the first time (no history)
      isFirstTime = recommendation['is_first_time'] ?? false;
      
      if (isFirstTime) {
        // Use appropriate first-time message based on time
        firstTimeMessage = isAfterSixPm 
            ? 'පොහොර යෙදීම හෙටින් ආරම්භ කරන්න'  // Start fertilizing from tomorrow
            : 'පොහොර යෙදීම අදින් ආරම්භ කරන්න';   // Start fertilizing from today
            
        // Get the fertilizer in Sinhala if available
        nextFertilizerSinhala = recommendation['next_fertilizer_sinhala'] ?? '';
      } 
      else if (recommendation['recommended_date'] != null) {
        // Not first time, show next date and fertilizer type
        nextDate = recommendation['recommended_date'];
        nextFertilizer = recommendation['next_fertilizer'] ?? '';
        nextFertilizerSinhala = recommendation['next_fertilizer_sinhala'] ?? nextFertilizer;
        hasRecommendation = true;
      }
    }
    
    // Check if we have day names in Sinhala
    String nextDateFormatted = '';
    if (nextDate.isNotEmpty) {
      try {
        final dateObj = DateTime.parse(nextDate);
        nextDateFormatted = DateFormat('yyyy-MM-dd').format(dateObj);
      } catch (e) {
        nextDateFormatted = nextDate;
      }
    }
    
    return Card(
      margin: EdgeInsets.zero,
      color: effectiveIsSuitable ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
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
            if (isFirstTime) ...[
              const SizedBox(height: 8),
              Text(
                firstTimeMessage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (nextFertilizerSinhala.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'පොහොර වර්ගය: $nextFertilizerSinhala',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ] else if (hasRecommendation) ...[
              const SizedBox(height: 8),
              Text(
                'මීළඟ යෙදීම: $nextDateFormatted',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'පොහොර වර්ගය: $nextFertilizerSinhala',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
            // Refresh button removed
          ],
        ),
      ),
    );
  }
}