import 'package:betlecare/pages/harvest/predict/previous_predictions_page.dart';
import 'package:betlecare/pages/harvest/predict/yield_summary_page.dart';
import 'package:betlecare/services/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class YieldMainPage extends StatefulWidget {
  const YieldMainPage({super.key});

  @override
  _YieldMainPageState createState() => _YieldMainPageState();
}

class _YieldMainPageState extends State<YieldMainPage> {
  late SupabaseService _supabaseService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSupabaseService();
  }

  Future<void> _initializeSupabaseService() async {
    _supabaseService = await SupabaseService.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: 'අස්වැන්න පිළිබඳ \nසාරාංශය',
              color: Colors.orange.shade100,
              imagePath: 'assets/images/eshan/LM8.png',
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
              onTap: () {
                if (!_isInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('කරුණාකර මොහොතක් රැඳී සිටින්න...')),
                  );
                  return;
                }
                _showLandSelectionDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'පෙර \nපුරෝකථනයන්',
              color: Colors.teal.shade100,
              imagePath: 'assets/images/eshan/LM9.png',
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade50,
                  Colors.teal.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreviousPredictionsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Color color,
    required String imagePath,
    required Gradient gradient,
    required Function()? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLandSelectionDialog(BuildContext context) async {
    setState(() => _isInitialized = false);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final lands = await _supabaseService.read('land_size',
          column: 'user_id', value: userId);

      setState(() => _isInitialized = true);

      if (lands.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('ඉඩම් දත්ත නොමැත. කරුණාකර පළමුව ඉඩමක් එකතු කරන්න.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ඉඩම තෝරන්න'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lands.length,
                itemBuilder: (context, index) {
                  final land = lands[index];
                  return ListTile(
                    leading: Icon(Icons.landscape, color: Colors.brown),
                    title: Text(land['name']),
                    subtitle: Text('${land['area'].toStringAsFixed(2)} අක්කර'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              YieldSummaryPage(landName: land['name']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('අවලංගු කරන්න'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() => _isInitialized = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ඉඩම් දත්ත ලබා ගැනීමේ දෝෂයක්: $e')),
      );
    }
  }
}
