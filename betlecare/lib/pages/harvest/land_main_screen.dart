import 'package:betlecare/pages/harvest/land_details_screen.dart';
import 'package:flutter/material.dart';

import '../../widgets/appbar/app_bar.dart';
import 'harvest_screen.dart';
import 'land_measurement_screen.dart';
import 'manual_land_measurement_page.dart';

class LandMainScreen extends StatelessWidget {
  const LandMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const BasicAppbar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildCard(
                      title: 'සිතියම මත පදනම්\n වූ ඉඩම් මැනීම',
                      color: Colors.blue.shade100,
                      imagePath: 'assets/images/eshan/LM5.png',
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                      ),
                      onTap: () => _navigateTo(
                          context, const ManualLandMeasurementPage()),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'GPS මත පදනම්\n වූ ඉඩම් මැනීම',
                      color: Colors.purple.shade100,
                      imagePath: 'assets/images/eshan/LM6.png',
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade50, Colors.purple.shade100],
                      ),
                      onTap: () =>
                          _navigateTo(context, const LandMeasurementScreen()),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'ඉඩම් විස්තර',
                      color: Colors.green.shade100,
                      imagePath: 'assets/images/eshan/LM7.png',
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                      ),
                      onTap: () =>
                          _navigateTo(context, const LandDetailsScreen()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildPageWrapper(child: page),
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
