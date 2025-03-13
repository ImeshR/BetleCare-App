import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';

class PestPage extends StatelessWidget {
  final String imagePath;

  const PestPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පළිබෝධ හඳුනාගැනීම'),
        backgroundColor: Colors.green.shade100,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ඔබගේ ඡායාරූපය විශ්ලේෂණය කරමින්...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),
              // Display the captured or uploaded image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // If asset loading fails, try to load as file
                    return Image.file(
                      File(imagePath),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Text('ඡායාරූපය පෙන්විය නොහැක'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Placeholder content for pest detection results
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'හඳුනාගත් පළිබෝධය:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ඔබගේ ඡායාරූපය විශ්ලේෂණය කරමින් පවතී. මෙය මිනිත්තු කිහිපයක් ගත විය හැකිය.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onTabChange: (index) {
          // Handle navigation between tabs
        },
      ),
    );
  }
}
