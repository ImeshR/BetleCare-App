import 'package:betlecare/pages/harvest/land_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../widgets/appbar/app_bar.dart';
import '../user/user-settings-page.dart';
import 'harvest_screen.dart';
import 'land_measurement_screen.dart';
import 'manual_land_measurement_page.dart';

class LandMainScreen extends StatelessWidget {
  const LandMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                    /// Check payment status using Consumer
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final userProvider = Provider.of<UserProvider>(context);
                        final userSettings = userProvider.userSettings;
                        bool isPaid = userSettings?['payment_status'] ?? false;

                        return Opacity(
                          opacity: isPaid ? 1.0 : 0.5, // Dim if not paid
                          child: Stack(
                            children: [
                              IgnorePointer(
                                ignoring: !isPaid, // Disable tap if not paid
                                child: _buildCard(
                                  title: 'GPS මත පදනම්\n වූ ඉඩම් මැනීම',
                                  color: Colors.purple.shade100,
                                  imagePath: 'assets/images/eshan/LM6.png',
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.shade50,
                                      Colors.purple.shade100
                                    ],
                                  ),
                                  onTap: () => _navigateTo(
                                      context, const LandMeasurementScreen()),
                                ),
                              ),
                              if (!isPaid)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(
                                        0.4), // Overlay for dimming
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '🌟 මෙය ප්‍රිමියම් විශේෂාංගයකි!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () => _navigateTo(
                                              context, UserSettingsPage()),
                                          child:
                                              Text('මාසික පැකේජය මිලදී ගන්න'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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
