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
  
  Color _getRecommendationColor(String recommendation) {
    if (recommendation.contains("No watering")) {
      return Colors.green;
    } else if (recommendation.contains("once")) {
      return Colors.blue;
    } else {
      return Colors.indigo;
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('ජල නිර්දේශ ලබා ගැනෙයි...'),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _recommendation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ජල නිර්දේශය ලබාගැනීමට නොහැකි විය',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final recommendation = _recommendation!['watering_recommendation'] ?? '';
    final waterAmount = _recommendation!['water_amount'] ?? 0;
    final color = _getRecommendationColor(recommendation);
    final icon = _getRecommendationIcon(recommendation);
    final text = _getLocalizedRecommendation(recommendation, waterAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}