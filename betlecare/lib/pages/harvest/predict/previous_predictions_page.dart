import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PreviousPredictionsPage extends StatefulWidget {
  const PreviousPredictionsPage({super.key});

  @override
  _PreviousPredictionsPageState createState() =>
      _PreviousPredictionsPageState();
}

class _PreviousPredictionsPageState extends State<PreviousPredictionsPage> {
  late Future<List<Map<String, dynamic>>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  void _loadPredictions() {
    _predictionsFuture = Supabase.instance.client
        .from('harvest_predict_history')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<void> _deletePrediction(String id) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Delete the prediction
      await Supabase.instance.client
          .from('harvest_predict_history')
          .delete()
          .eq('id', id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('පුරෝකථනය සාර්ථකව මකා දමන ලදී')),
        );
      }

      // Refresh the predictions list
      setState(() {
        _loadPredictions();
      });
    } catch (error) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('දෝෂයක් ඇති විය: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පෙර පුරෝකථනයන්'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _predictionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('පෙර පුරෝකථන නැත'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final prediction = snapshot.data![index];
                return _buildPredictionCard(prediction);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final expectedHarvestDate =
        DateFormat('yyyy-MM-dd').parse(prediction['expected_harvest_date']);
    final formattedDate = DateFormat('yyyy-MM-dd').format(expectedHarvestDate);
    final landName = prediction['land_name'] ?? 'N/A';
    final landLocation = prediction['land_location'] ?? 'N/A';
    final predictedP = prediction['predicted_p'].toInt();
    final predictedKT = prediction['predicted_kt'].toInt();
    final predictedRKT = prediction['predicted_rkt'].toInt();
    final id = prediction['id'] as String;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow(Icons.calendar_today, "දින: $formattedDate"),
                _buildRow(Icons.landscape, "ඉඩම: $landName ($landLocation)"),
                _buildRow(Icons.straighten,
                    "ඉඩම් ප්‍රමාණය: ${prediction['land_size']} අක්කර"),
                _buildRow(Icons.layers, "පස වර්ගය: ${prediction['soil_type']}"),
                _buildRow(Icons.agriculture,
                    "රෝපණය කළ ඉණි ගණන: ${prediction['planted_sticks']}"),
                const Divider(),
                _buildRow(Icons.eco, "පීදුනු කොළ (P): $predictedP"),
                _buildRow(Icons.eco, "කෙටි කොළ (KT): $predictedKT"),
                _buildRow(Icons.eco, "රෑන් කෙටි කොළ (RKT): $predictedRKT"),
              ],
            ),
          ),

          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(id);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('තහවුරු කිරීම'),
          content: const Text('මෙම පුරෝකථනය මකා දැමීමට අවශ්‍යද?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('අවලංගු කරන්න'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePrediction(id);
              },
              child: const Text('මකන්න', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
