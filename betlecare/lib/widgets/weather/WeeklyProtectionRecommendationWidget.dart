
// WEEKLY PROTECTION RECOMMENDATION WIDGET

import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/protection_service.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:intl/intl.dart';

class WeeklyProtectionRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const WeeklyProtectionRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);
  
  @override
  State<WeeklyProtectionRecommendationWidget> createState() => _WeeklyProtectionRecommendationWidgetState();
}

class _WeeklyProtectionRecommendationWidgetState extends State<WeeklyProtectionRecommendationWidget> {
  final ProtectionService _protectionService = ProtectionService();
  final WeatherService _weatherService = WeatherService();
  
  bool _isLoading = false;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _consolidatedRecommendations = [];
  Map<String, dynamic>? _currentPeriod;
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
      _consolidatedRecommendations = [];
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
      
      // Extract rainfall and temperature forecasts
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
      
      // Get consolidated protection forecast
      final forecastResponse = await _protectionService.getConsolidatedProtectionForecast(
        widget.bed.district,
        rainfallForecast,
        minTempForecast,
        maxTempForecast,
      );
      
      if (forecastResponse['has_protection_days'] && 
          forecastResponse['consolidated_recommendations'] != null) {
        
        final recommendations = forecastResponse['consolidated_recommendations'] as List;
        
        // Map the consolidated recommendations
        List<Map<String, dynamic>> processedRecommendations = [];
        
        for (var rec in recommendations) {
          processedRecommendations.add({
            'date_range': rec['date_range'],
            'protection_type': rec['protection_type'],
            'protection_label_sinhala': rec['protection_label_sinhala'],
            'methods': rec['methods'] ?? [],
            'reason': rec['reason'],
            'days_count': rec['days_count'],
            'max_temperature': rec['max_temperature'],
            'max_rainfall': rec['max_rainfall'],
            'isSelected': false,
          });
        }
        
        setState(() {
          _consolidatedRecommendations = processedRecommendations;
          
          // Set the first period as current if available
          if (processedRecommendations.isNotEmpty) {
            _currentPeriod = Map<String, dynamic>.from(processedRecommendations.first);
            _currentPeriod!['isSelected'] = true;
            
            // Update the isSelected flag in the list
            _consolidatedRecommendations[0]['isSelected'] = true;
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _consolidatedRecommendations = [];
          _currentPeriod = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🛡️ Error in WeeklyProtectionRecommendationWidget: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Check if there are any protection days in the forecast
  bool get _hasProtectionDays => _consolidatedRecommendations.isNotEmpty;
  
  @override
  Widget build(BuildContext context) {
    // If there are no protection days, return an empty container
    if (!_isLoading && _errorMessage.isEmpty && !_hasProtectionDays) {
      return Container(); // Don't show anything if no protection needed
    }
    
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_currentPeriod == null) {
      return Container(); // No protection needed
    }
    
    return _buildRecommendationCard();
  }
  
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
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
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
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
    );
  }
  
  Widget _buildRecommendationCard() {
    if (_currentPeriod == null) {
      return Container(); // This shouldn't happen based on our previous checks
    }
    
    // Get protection properties
    final protectionType = _currentPeriod!['protection_type'] as int;
    final labelSinhala = _currentPeriod!['protection_label_sinhala'] as String;
    final methods = _currentPeriod!['methods'] as List;
    final reason = _currentPeriod!['reason'] as String;
    final dateRange = _currentPeriod!['date_range'] as String;
    
    // Use consistent red color for protection regardless of type
    final color = Colors.red.shade700;
    final icon = protectionType == 1 ? Icons.wb_sunny : Icons.umbrella;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: color),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ආරක්ෂණ නිර්දේශයන්',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          
          // Current protection period recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelSinhala,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
                if (methods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (methods as List).map((method) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: color),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                method.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
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
          
          // Consolidated periods when expanded
          if (_isExpanded && _consolidatedRecommendations.length > 1) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'සති පුරා ආරක්ෂණ කාල පරාසයන්',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // List of protection periods
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _consolidatedRecommendations.length,
              itemBuilder: (context, index) {
                final period = _consolidatedRecommendations[index];
                final isSelected = period['isSelected'] == true;
                final periodType = period['protection_type'] as int;
                final periodIcon = periodType == 1 ? Icons.wb_sunny : Icons.umbrella;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      // Update selection in the list
                      for (var i = 0; i < _consolidatedRecommendations.length; i++) {
                        _consolidatedRecommendations[i]['isSelected'] = (i == index);
                      }
                      
                      // Update current period
                      _currentPeriod = Map<String, dynamic>.from(_consolidatedRecommendations[index]);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red.shade100 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.red.shade400 : Colors.red.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(periodIcon, size: 20, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                period['date_range'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: color,
                                ),
                              ),
                              Text(
                                _getShortProtectionLabelWithReason(periodType, period['reason']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, size: 16, color: color),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  String _getShortProtectionLabelWithReason(int protectionType, String reason) {
    // Extract the first part of the reason (before the comma or period)
    String shortReason = reason;
    if (reason.contains(',')) {
      shortReason = reason.split(',').first;
    } else if (reason.contains('.')) {
      shortReason = reason.split('.').first;
    }
    
    // Return shortened reason
    return shortReason;
  }
}
