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
            //  WeatherDisplayCard
            const WeatherDisplayCard(),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ඉදිරි සතියේ \nකාලගුණ තත්වය',
              color: Colors.purple.shade100,
              imagePath: 'assets/images/weather/weather2.png',
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChildPageWrapper(child: const WeatherScreen2()),
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
                Container(
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
