
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/protection_service.dart';
import 'package:betlecare/services/weather_services2.dart';

class ProtectionRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const ProtectionRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);
  
  @override
  State<ProtectionRecommendationWidget> createState() => _ProtectionRecommendationWidgetState();
}

class _ProtectionRecommendationWidgetState extends State<ProtectionRecommendationWidget> {
  final ProtectionService _protectionService = ProtectionService();
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _protectionForecast;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get weather data for forecast
      final weatherData = await _weatherService.fetchWeatherData(widget.bed.district);
      
      if (weatherData == null) {
        setState(() {
          _errorMessage = 'Weather data not available';
          _isLoading = false;
        });
        return;
      }
      
      // Extract rainfall forecast
      List<double> rainfallForecast = [];
      List<double> minTempForecast = [];
      List<double> maxTempForecast = [];
      
      if (weatherData['daily'] != null) {
        // Get rainfall data
        if (weatherData['daily']['precipitation_sum'] != null) {
          final precipitationData = weatherData['daily']['precipitation_sum'];
          for (var i = 0; i < precipitationData.length && i < 7; i++) {
            rainfallForecast.add(precipitationData[i].toDouble());
          }
        }
        
        // Get min temperature data
        if (weatherData['daily']['temperature_2m_min'] != null) {
          final minTempData = weatherData['daily']['temperature_2m_min'];
          for (var i = 0; i < minTempData.length && i < 7; i++) {
            minTempForecast.add(minTempData[i].toDouble());
          }
        }
        
        // Get max temperature data
        if (weatherData['daily']['temperature_2m_max'] != null) {
          final maxTempData = weatherData['daily']['temperature_2m_max'];
          for (var i = 0; i < maxTempData.length && i < 7; i++) {
            maxTempForecast.add(maxTempData[i].toDouble());
          }
        }
      }
      
      // Pad with zeros/defaults if we don't have 7 days
      while (rainfallForecast.length < 7) {
        rainfallForecast.add(0.0);
      }
      while (minTempForecast.length < 7) {
        minTempForecast.add(24.0);
      }
      while (maxTempForecast.length < 7) {
        maxTempForecast.add(32.0);
      }
      
      // Get protection forecast
      final forecastResponse = await _protectionService.getProtectionForecast(
        widget.bed.district,
        rainfallForecast,
        minTempForecast,
        maxTempForecast,
      );
      
      setState(() {
        _protectionForecast = forecastResponse;
        _isLoading = false;
      });
    } catch (e) {
      print('🛡️ Error in ProtectionRecommendationWidget: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Check if there are any protection days in the forecast
  bool get _hasProtectionDays {
    if (_protectionForecast == null || 
        !_protectionForecast!.containsKey('daily_recommendations')) {
      return false;
    }
    
    final recommendations = _protectionForecast!['daily_recommendations'] as List;
    return recommendations.any((day) => day['protection_type'] > 0);
  }
  
  // Get the most urgent protection day (closest day requiring protection)
  Map<String, dynamic>? get _mostUrgentProtectionDay {
    if (_protectionForecast == null || 
        !_protectionForecast!.containsKey('daily_recommendations')) {
      return null;
    }
    
    final recommendations = _protectionForecast!['daily_recommendations'] as List;
    
    // First check if today needs protection
    final today = recommendations.firstWhere(
      (day) => day['protection_type'] > 0 && DateTime.parse(day['date']).day == DateTime.now().day,
      orElse: () => {},
    );
    
    if (today.isNotEmpty) {
      return today;
    }
    
    // Then find the earliest day needing protection
    for (var day in recommendations) {
      if (day['protection_type'] > 0) {
        return day;
      }
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    // If there are no protection days, return an empty container with fixed height for consistent spacing
    if (!_isLoading && _errorMessage.isEmpty && _protectionForecast != null && !_hasProtectionDays) {
      return Container(); // Don't show anything if no protection needed
    }
    
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_protectionForecast == null) {
      return _buildUnavailableState();
    }
    
    return _buildRecommendationCard();
  }
  
  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.shield, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ආරක්ෂණ නිර්දේශය ලබා ගනිමින්...',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ආරක්ෂණ නිර්දේශය ලබා ගත නොහැක',
                    style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loadRecommendations,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('නැවත උත්සාහ කරන්න'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnavailableState() {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.shield, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ආරක්ෂණ නිර්දේශය ලබා ගත නොහැක',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            TextButton(
              onPressed: _loadRecommendations,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('නැවත උත්සාහ කරන්න'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationCard() {
    final urgentDay = _mostUrgentProtectionDay;
    
    if (urgentDay == null) {
      return Container(); // This shouldn't happen since we check _hasProtectionDays
    }
    
    // Get protection type and details
    final protectionType = urgentDay['protection_type'] as int;
    final protectionLabel = urgentDay['protection_label_sinhala'] as String;
    final dayName = urgentDay['day_name_sinhala'] as String;
    final date = DateTime.parse(urgentDay['date']);
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Get protection methods
    final methods = urgentDay['protection_methods_sinhala'] as List<dynamic>;
    
    // Always use red color theme for protection
    final textColor = Colors.red.shade700;
    final iconData = protectionType == 1 ? Icons.wb_sunny : Icons.umbrella;
    
    // Build the card
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    protectionLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$dayName ($dateString)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            // Show protection methods
            if (methods.isNotEmpty) ...[
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: methods.take(2).map((method) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right, size: 16, color: textColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            method,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

 