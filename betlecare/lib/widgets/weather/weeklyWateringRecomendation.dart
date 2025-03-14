
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/wateringService.dart';
import 'package:intl/intl.dart';

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
      // Get today's recommendation
      final result = await _wateringService.getWateringRecommendation(widget.bed);
      
      // Simulate weekly forecast (in a real app, you'd fetch this from your backend)
      // This is a placeholder until you implement the actual API endpoint
      final List<Map<String, dynamic>> weeklyForecast = [];
      final today = DateTime.now();
      
      // Add today's recommendation
      weeklyForecast.add({
        'date': today,
        'day': _getDayName(today),
        'recommendation': result['watering_recommendation'],
        'water_amount': result['water_amount'],
        'confidence': result['confidence'],
      });
      
      // Generate placeholder recommendations for the next 6 days
      for (int i = 1; i < 7; i++) {
        final date = today.add(Duration(days: i));
        
        // This is simulated data - replace with actual API calls when available
        String recommendation;
        int waterAmount;
        double confidence;
        
        // Simple simulation logic - alternating recommendations
        if (i % 3 == 0) {
          recommendation = "Water twice today";
          waterAmount = 8;
          confidence = 85.0;
        } else if (i % 2 == 0) {
          recommendation = "Water once today";
          waterAmount = 4;
          confidence = 75.0;
        } else {
          recommendation = "No watering needed";
          waterAmount = 0;
          confidence = 90.0;
        }
        
        weeklyForecast.add({
          'date': date,
          'day': _getDayName(date),
          'recommendation': recommendation,
          'water_amount': waterAmount,
          'confidence': confidence,
        });
      }
      
      setState(() {
        _todayRecommendation = result;
        _weeklyForecast = weeklyForecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getDayName(DateTime date) {
    // Get Sinhala day name
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
    if (recommendation.contains("No watering")) {
      return 'ජලය යෙදීම අවශ්‍ය නැත';
    } else if (recommendation.contains("once")) {
      return 'ජලය යෙදීම අවශ්‍යයි (${waterAmount}L)';
    } else {
      return 'දෙවරක් ජලය යෙදීම අවශ්‍යයි (${waterAmount}L)';
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
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weeklyForecast.length,
                    itemBuilder: (context, index) {
                      final day = _weeklyForecast[index];
                      final icon = _getRecommendationIcon(day['recommendation']);
                      
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day['day'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MM/dd').format(day['date']),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(icon, color: Colors.blue.shade700, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '${day['water_amount']}L',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
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