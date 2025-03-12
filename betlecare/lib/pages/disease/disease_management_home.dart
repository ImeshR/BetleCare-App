import 'package:flutter/material.dart';

class DiseaseManagementScreen extends StatelessWidget {
  const DiseaseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Management'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: 'රෝග හඳුනාගැනීම',
              color: Colors.red.shade100,
              imagePath:
                  '../../../assets/images/disease/Disease Detection.png', // Added image
              onTap: () {
                // Navigate to Disease Detection Page
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Treatment Plans',
              color: Colors.blue.shade100,
              icon: Icons.medical_services,
              onTap: () {
                // Navigate to Treatment Plans Page
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Disease Spread Map',
              color: Colors.green.shade100,
              icon: Icons.map,
              onTap: () {
                // Navigate to Disease Spread Map Page
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
    IconData? icon,
    String? imagePath, // Added image path parameter
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 50, // Adjust size as needed
                height: 50,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: 40, color: Colors.black54),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
