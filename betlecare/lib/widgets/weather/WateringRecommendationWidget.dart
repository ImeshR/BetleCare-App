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
  String _recommendation = '';
  int _waterAmount = 0;
  double _confidence = 0.0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchWateringRecommendation();
  }

  Future<void> _fetchWateringRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _wateringService.getWateringRecommendation(widget.bed);
      
      setState(() {
        _recommendation = result['watering_recommendation'] ?? '';
        _waterAmount = result['water_amount'] ?? 0;
        _confidence = result['confidence'] ?? 0.0;
        _error = result['error'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: double.infinity,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20, 
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            'ජල නිර්දේශය ලබාගැනීමට නොහැකි විය',
            style: TextStyle(color: Colors.red[700], fontSize: 13),
          ),
        ),
      );
    }

    // Determine color and icon based on recommendation
    Color color;
    IconData icon;
    String localizedText;

    if (_recommendation.contains('No watering')) {
      color = Colors.green;
      icon = Icons.check_circle;
      localizedText = 'ජලය යෙදීම අවශ්‍ය නැත';
    } else if (_recommendation.contains('once')) {
      color = Colors.blue;
      icon = Icons.water_drop;
      localizedText = 'අද ජලය යෙදීම අවශ්‍යයි (${_waterAmount}L)';
    } else {
      color = Colors.indigo;
      icon = Icons.water;
      localizedText = 'අද දෙවරක් ජලය යෙදීම අවශ්‍යයි (${_waterAmount}L)';
    }

    // Return a full-width elevated button-like container with the recommendation
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: () {
          // Show more details if needed
        },
        icon: Icon(icon, size: 20),
        label: Text(localizedText),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}