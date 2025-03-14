import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'dart:io';
import 'pestpage.dart';

class DiseasePhotoManagementPage extends StatefulWidget {
  const DiseasePhotoManagementPage({super.key});

  @override
  State<DiseasePhotoManagementPage> createState() =>
      _DiseasePhotoManagementPageState();
}

class _DiseasePhotoManagementPageState
    extends State<DiseasePhotoManagementPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ඡායාරූපය සාර්ථකව ගන්නා ලදී')),
        );

        // Navigate to pest page with bottom nav bar
        // We use Future.delayed to ensure the snackbar is visible before navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PestPage(imagePath: photo.path),
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ඡායාරූපය සාර්ථකව උඩුගත කරන ලදී')),
        );

        // Navigate to pest page with bottom nav bar
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PestPage(imagePath: image.path),
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('රෝග ඡායාරූප'),
        backgroundColor: Colors.green.shade100,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ඔබගේ ශාක රෝග හඳුනා ගැනීමට ඡායාරූප ගන්න හෝ උඩුගත කරන්න',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildCard(
              title: 'ඡායාරූපයක් ගන්න',
              description: 'ඔබගේ ශාකයේ රෝග ලක්ෂණ ඡායාරූපයක් ගන්න',
              color: Colors.green.shade100,
              imagePath: 'assets/images/disease/DD4.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              icon: Icons.camera_alt,
              onTap: _isLoading ? null : _takePicture,
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ඡායාරූපයක් උඩුගත කරන්න',
              description: 'ඔබගේ ගැලරියෙන් ඡායාරූපයක් තෝරන්න',
              color: Colors.purple.shade100,
              imagePath: 'assets/images/disease/gallery.png',
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
              ),
              icon: Icons.photo_library,
              onTap: _isLoading ? null : _uploadPhoto,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('කරුණාකර රැඳී සිටින්න...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required Color color,
    String? imagePath,
    required Gradient gradient,
    required IconData icon,
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            icon,
                            size: 60,
                            color: color
                                .withRed(color.red - 40)
                                .withGreen(color.green - 40)
                                .withBlue(color.blue - 40),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
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
      ),
    );
  }
}

// Pest page that will be shown after taking or uploading a photo
