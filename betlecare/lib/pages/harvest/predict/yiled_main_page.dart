import 'package:betlecare/pages/harvest/predict/previous_predictions_page.dart';
import 'package:betlecare/pages/harvest/predict/yield_summary_page.dart';
import 'package:flutter/material.dart';

class YieldMainPage extends StatelessWidget {
  const YieldMainPage({super.key});

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
              imagePath: 'assets/images/eshan/summary.png',
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const YieldSummaryPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'පෙර \nපුරෝකථනයන්',
              color: Colors.teal.shade100,
              imagePath: 'assets/images/eshan/predictions.png',
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
}
