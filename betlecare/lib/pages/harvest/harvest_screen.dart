import 'package:betlecare/pages/harvest/predict/add_prediction_page.dart';
import 'package:betlecare/pages/harvest/predict/yiled_main_page.dart';
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';
import 'land_main_screen.dart';

class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: 'අස්වැන්න පිළිබඳ\nපුරෝකථනය',
              color: Colors.green.shade100,
              imagePath: 'assets/images/eshan/LM1.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: AddPredictionPage()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ඉඩම් කොටස\n මැනීම හා විස්තර',
              color: Colors.purple.shade100,
              imagePath: 'assets/images/eshan/LM2.png',
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
                        const ChildPageWrapper(child: LandMainScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'අස්වැන්න පිළිබඳ \nසාරාංශය හා පෙර \nපුරෝකථනයන්',
              color: Colors.amber.shade100,
              imagePath: 'assets/images/eshan/LM4.png',
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade50,
                  Colors.amber.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: YieldMainPage()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'කොළ ප්‍රමාණ\nපරිවර්තනය',
              color: Colors.blue.shade100,
              imagePath: 'assets/images/eshan/LM3.png',
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: LandMainScreen()),
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
    required String imagePath, // Accept image path
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
                  width: 160, // Set the container size to match the image size
                  height: 160, // Set the container size to match the image size
                  child: Center(
                    child: Image.asset(
                      imagePath, // Use the image path
                      width: 160, // Set the image width
                      height: 160, // Set the image height
                      fit: BoxFit
                          .contain, // Ensure the image fits without distortion
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      textAlign:
                          TextAlign.center, // Ensure text alignment is centered
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
        selectedIndex: 0,
        onTabChange: (index) {
          Navigator.pop(context);
        },
      ),
    );
  }
}
