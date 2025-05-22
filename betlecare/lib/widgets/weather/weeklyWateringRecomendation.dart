import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/wateringService.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class WeeklyWateringRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const WeeklyWateringRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);

  @override
  State<WeeklyWateringRecommendationWidget> createState() => _WeeklyWateringRecommendationWidgetState();
}

class _WeeklyWateringRecommendationWidgetState extends State<WeeklyWateringRecommendationWidget> {
  final _wateringService = WateringService();
  final _weatherService = WeatherService();
  bool _isLoading = true;
  bool _isExpanded = false;
  String _error = '';
  Map<String, dynamic>? _todayRecommendation;
  List<Map<String, dynamic>> _weeklyForecast = [];

  @override
  void initState() {
    super.initState();
    _fetchWateringRecommendations();
  }

  Future<void> _fetchWateringRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // get weather data for the bed's location to create forecasts
      final String locationKey = _getLocationKeyFromDistrict(widget.bed.district);
      final weatherData = await _weatherService.fetchWeatherData(locationKey);
      
      if (weatherData == null) {
        throw Exception('Failed to fetch weather data');
      }
      
      // Get daily forecasts for the next 7 days
      final List<Map<String, dynamic>> dailyForecasts = _weatherService.prepareDailyForecast(weatherData);
      developer.log('Daily forecasts fetched: ${dailyForecasts.length} days', name: 'WeeklyWateringWidget');
      
      // Get today's recommendation from the API
      final todayResult = await _wateringService.getWateringRecommendation(widget.bed);
      
      // Create weekly forecast array
      final List<Map<String, dynamic>> weeklyForecast = [];
      final today = DateTime.now();
      

      weeklyForecast.add({
        'date': today,
        'day': _getDayName(today),
        'recommendation': todayResult['watering_recommendation'],
        'water_amount': todayResult['water_amount'],
        'confidence': todayResult['confidence'],
        'rainfall': dailyForecasts[0]['rainfall'],
        'maxTemp': dailyForecasts[0]['maxTemp'],
        'minTemp': dailyForecasts[0]['minTemp'],
      });
      

      for (int i = 1; i < dailyForecasts.length && i < 7; i++) {
        final date = today.add(Duration(days: i));
        final forecast = dailyForecasts[i];
        final dayName = _getDayName(date);
        

        final recommendation = _getRecommendationFromWeather(
          forecast['rainfall'],
          forecast['minTemp'],
          forecast['maxTemp'],
          _calculateCropStage(widget.bed.plantedDate),
          dayName,
        );
        
        weeklyForecast.add({
          'date': date,
          'day': dayName,
          'recommendation': recommendation['recommendation'],
          'water_amount': recommendation['water_amount'],
          'confidence': recommendation['confidence'],
          'rainfall': forecast['rainfall'],
          'maxTemp': forecast['maxTemp'],
          'minTemp': forecast['minTemp'],
        });
      }
      
      setState(() {
        _todayRecommendation = todayResult;
        _weeklyForecast = weeklyForecast;
        _isLoading = false;
      });
      
      developer.log('Weekly watering recommendations completed', name: 'WeeklyWateringWidget');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      developer.log('Error fetching watering recommendations: $e', name: 'WeeklyWateringWidget', error: e);
    }
  }

 
  int _calculateCropStage(DateTime plantedDate) {
    final ageInDays = DateTime.now().difference(plantedDate).inDays;
    
    if (ageInDays < 30) return 1; 
    if (ageInDays < 60) return 3; 
    if (ageInDays < 90) return 5; 
    if (ageInDays < 180) return 7; 
    return 10; 
  }
  
  
  String _getLocationKeyFromDistrict(String district) {
    final districtMap = {
      'කුරුණෑගල': 'කුරුණෑගල (Kurunegala)',
      'කුරුණෑගල (Kurunegala)': 'කුරුණෑගල (Kurunegala)',
      'Kurunegala': 'කුරුණෑගල (Kurunegala)',
      'පුත්තලම': 'පුත්තලම (Puttalam)',
      'පුත්තලම (Puttalam)': 'පුත්තලම (Puttalam)',
      'Puttalam': 'පුත්තලම (Puttalam)',
      'අනමඩුව': 'අනමඩුව (Anamaduwa)',

    };
    
    return districtMap[district] ?? 'වත්මන් ස්ථානය (Current Location)';
  }


  Map<String, dynamic> _getRecommendationFromWeather(
    double rainfall, 
    int minTemp, 
    int maxTemp, 
    int cropStage,
    String dayName
  ) {
    String recommendation;
    int waterAmount;
    double confidence;
    

    if (rainfall >= 15) {
      
      recommendation = "No watering needed";
      waterAmount = 0;
      confidence = 90.0;
    } else if (rainfall >= 5) {
      
      if (maxTemp >= 32) {
        recommendation = "Water once today";
        waterAmount = 3;
        confidence = 75.0;
      } else {
        recommendation = "No watering needed";
        waterAmount = 0;
        confidence = 80.0;
      }
    } else if (rainfall > 0) {
      
      if (maxTemp >= 32) {
        recommendation = "Water once today";
        waterAmount = 4;
        confidence = 85.0;
      } else if (cropStage <= 3) {
        
        recommendation = "Water once today";
        waterAmount = 4;
        confidence = 80.0;
      } else {
        recommendation = "No watering needed";
        waterAmount = 0;
        confidence = 70.0;
      }
    } else {
      
      if (maxTemp >= 33) {
        if (dayName == 'බ්‍රහස්පතින්දා' || dayName == 'ඉරිදා') {
          
          recommendation = "Water once today";
          waterAmount = 5;
          confidence = 80.0;
        } else {
          recommendation = "Water twice today";
          waterAmount = 8;
          confidence = 90.0;
        }
      } else if (maxTemp >= 30) {
        recommendation = "Water once today";
        waterAmount = 5;
        confidence = 85.0;
      } else {
        if (cropStage <= 3) {
         
          recommendation = "Water once today";
          waterAmount = 4;
          confidence = 75.0;
        } else {
          recommendation = "Water once today";
          waterAmount = 4;
          confidence = 70.0;
        }
      }
    }
    
    return {
      'recommendation': recommendation,
      'water_amount': waterAmount,
      'confidence': confidence,
    };
  }

  String _getDayName(DateTime date) {
    
    final List<String> sinhalaWeekdays = [
      'ඉරිදා', 'සඳුදා', 'අඟහරුවාදා', 'බදාදා', 
      'බ්‍රහස්පතින්දා', 'සිකුරාදා', 'සෙනසුරාදා'
    ];
    
    return sinhalaWeekdays[date.weekday % 7];
  }
  
  IconData _getRecommendationIcon(String recommendation) {
    if (recommendation.contains("No watering")) {
      return Icons.check_circle;
    } else if (recommendation.contains("once")) {
      return Icons.water_drop;
    } else {
      return Icons.water;
    }
  }
  
  String _getLocalizedRecommendation(String recommendation, int waterAmount) {
    final int totalWater = (waterAmount * widget.bed.areaSize).round();
    final int halfTotalWater = (totalWater / 2).round();
    
    if (recommendation.contains("No watering")) {
      return 'ජලය යෙදීම අවශ්‍ය නැත';
    } else if (recommendation.contains("once")) {
      return 'වර්ග මීටරයට ලීටර් $waterAmount\nඑනම් ඔබගේ වගාවට ලීටර් $totalWater ක් යොදන්න';
    } else {
      return 'දෙවරක් ජලය යෙදීම අවශ්‍යයි:\nවර්ග මීටරයට ලීටර් $waterAmount එනම් මුලු ලීටර් $totalWater ක් යොදන්න';
    }
  }

  String _getDetailedWateringText(String recommendation, int waterAmount) {
    final int totalWater = (waterAmount * widget.bed.areaSize).round();
    final int halfTotalWater = (totalWater / 2).round();
    
    if (recommendation.contains("No watering")) {
      return 'ජලය යෙදීම අවශ්‍ය නැත';
    } else if (recommendation.contains("once")) {
      return 'වර්ග මීටරයට ලීටර් $waterAmount\nඑනම් ඔබගේ වගාවට ලීටර් $totalWater ක් යොදන්න';
    } else {
      return 'වර්ග මීටරයට ලීටර් $waterAmount\nඑනම් ඔබගේ වගාවට ලීටර් $totalWater ක් යොදන්න.\nමෙම ප්‍රමානය දිනකට ලීටර් $halfTotalWater බැගින් යෙදීම වඩා යෝග්‍ය වේ';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ජල නිර්දේශ ලබා ගැනෙයි...',
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ජල නිර්දේශය ලබාගැනීමට නොහැකි විය',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $_error',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _fetchWateringRecommendations,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
                child: const Text('නැවත උත්සාහ කරන්න'),
              ),
            ),
          ],
        ),
      );
    }

    final today = _weeklyForecast.isNotEmpty ? _weeklyForecast[0] : null;
    
    if (today == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRecommendationIcon(today['recommendation']),
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ජලය යෙදීම සදහා නිර්දේශයන්',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLocalizedRecommendation(
                        today['recommendation'],
                        today['water_amount'],
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
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
          if (_isExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                const Text(
                  'සති පුරා ජල නිර්දේශ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,  
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weeklyForecast.length,
                    itemBuilder: (context, index) {
                      final day = _weeklyForecast[index];
                      final icon = _getRecommendationIcon(day['recommendation']);
                      
                      return Container(
                        width: 150, 
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  day['day'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(icon, color: Colors.blue.shade700, size: 18),
                              ],
                            ),
                            Text(
                              DateFormat('yyyy/MM/dd').format(day['date']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.thermostat, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${day['minTemp']}°-${day['maxTemp']}°',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.water_drop, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${day['rainfall']}mm',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Divider(height: 8),
                            const SizedBox(height: 4),
                            Text(
                              _getDetailedWateringText(
                                day['recommendation'],
                                day['water_amount'],
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}