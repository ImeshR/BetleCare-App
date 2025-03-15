import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';
import 'disease_detection.dart';
import 'pestpage.dart';

class DiseaseManagementScreen extends StatelessWidget {
  const DiseaseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: 'රෝග හඳුනාගැනීම',
              color: Colors.red.shade100,
              imagePath: 'assets/images/disease/DD1.png',
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.red.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChildPageWrapper(
                        child: DiseasePhotoManagementPage()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ප්‍රතිකාර සැලසුම්',
              color: Colors.blue.shade100,
              imagePath: '',
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              onTap: () {
                // Navigation will be added later
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'රෝග ව්‍යාප්ති\nසිතියම',
              color: Colors.green.shade100,
              imagePath: 'assets/images/disease/DD2.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              onTap: () {
                // Navigation will be added later
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
        selectedIndex: 3,
        onTabChange: (index) {
          Navigator.pop(context);
        },
      ),
    );
  }
}
