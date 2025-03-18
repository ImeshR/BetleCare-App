import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/weather/weather_display_card.dart';
import 'weather_screen_2.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WeatherDisplayCard
            const WeatherDisplayCard(),
            const SizedBox(height: 16),
            _buildWeeklyForecastCard(context),
          ],
        ),
      ),
    );
  }

Widget _buildWeeklyForecastCard(BuildContext context) {
  return Container(
    width: double.infinity,
    // Removed fixed height to let content determine size
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 251, 253, 255),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color.fromARGB(255, 187, 206, 221), width: 1),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChildPageWrapper(child: const WeatherScreen2()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Row(
            children: [
              SizedBox(
                width: 80, // Reduced size
                height: 80, // Reduced size
                child: Image.asset(
                  'assets/images/weather/weather2.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12), // Reduced spacing
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Use minimum required space
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ඉදිරි සතියේ කාලගුණ තත්වය',
                      style: TextStyle(
                        fontSize: 16, // Slightly smaller font
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Text(
                      'සති පුරා කාලගුණ විස්තර බලන්න',
                      style: TextStyle(
                        fontSize: 13, // Slightly smaller font
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced spacing
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14, // Smaller icon
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'තව දුරටත් කියවන්න',
                          style: TextStyle(
                            fontSize: 13, // Slightly smaller font
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
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
class ChildPageWrapper extends StatelessWidget {
  final Widget child;

  const ChildPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onTabChange: (index) {
          if (index != 4) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();

              Navigator.of(context)
                  .pushReplacementNamed('/main', arguments: index);
            });
          }
        },
      ),
    );
  }
}