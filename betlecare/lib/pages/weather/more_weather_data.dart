import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';

class MoreWeatherData extends StatelessWidget {
  const MoreWeatherData({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE3F2FD), // Light blue background
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'අද දින කාලගුණය',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.water_drop,
                              value: '0.0mm',
                              label: 'වර්ෂාපතනය',
                              iconColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.wb_sunny,
                              value: '23°C',
                              label: 'උෂ්ණත්වය',
                              iconColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.opacity,
                              value: '54%',
                              label: 'ආර්ද්රතාවය',
                              iconColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Bottom row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.thermostat,
                              value: '21°C',
                              label: 'අවම උෂ්ණත්වය',
                              iconColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.air,
                              value: '2kmh',
                              label: 'සුළඟේ වේගය',
                              iconColor: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildWeatherInfo(
                              icon: Icons.thermostat,
                              value: '24°C',
                              label: 'උපරිම උෂ්ණත්වය',
                              iconColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onTabChange: (index) {
          if (index != 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildWeatherInfo({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 40,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
