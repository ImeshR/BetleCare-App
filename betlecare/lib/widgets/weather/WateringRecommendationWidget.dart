
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/wateringService.dart';

class WateringRecommendationWidget extends StatefulWidget {
  final BetelBed bed;
  
  const WateringRecommendationWidget({
    Key? key,
    required this.bed,
  }) : super(key: key);

  @override
  State<WateringRecommendationWidget> createState() => _WateringRecommendationWidgetState();
}

class _WateringRecommendationWidgetState extends State<WateringRecommendationWidget> {
  final _wateringService = WateringService();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _recommendation;

  @override
  void initState() {
    super.initState();
    _fetchWateringRecommendation();
  }

  Future<void> _fetchWateringRecommendation() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await _wateringService.getWateringRecommendation(widget.bed);
      
      setState(() {
        _recommendation = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error fetching watering recommendation: $e');
    }
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
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue.shade700),
              const SizedBox(width: 18),
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
        ),
      );
    }

    if (_error.isNotEmpty || _recommendation == null) {
      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                  onPressed: _fetchWateringRecommendation,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                  child: const Text('නැවත උත්සාහ කරන්න'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recommendation = _recommendation!['watering_recommendation'] ?? '';
    final waterAmount = _recommendation!['water_amount'] ?? 0;
    final icon = _getRecommendationIcon(recommendation);
    final text = _getLocalizedRecommendation(recommendation, waterAmount);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}