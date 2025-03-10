import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/my_beds_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await betelBedProvider.loadBeds();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'දත්ත ලබා ගැනීමේ දෝෂයකි',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('නැවත උත්සාහ කරන්න'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Card
                            _buildWelcomeCard(context),
                            const SizedBox(height: 16),
                            
                            // Section Title
                            Text(
                              'ප්‍රධාන කාර්යයන්',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // My Beds Card - Main feature card
                            _buildFeatureCard(
                              context: context,
                              title: 'මගේ බුලත් පඳුරු',
                              description: 'ඔබගේ බුලත් පඳුරු කළමනාකරණය කරන්න',
                              iconData: Icons.spa,
                              color: Colors.green.shade200,
                              imagePath: 'assets/images/betel_leaf.png',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MyBedsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Tips and Advice Card
                            _buildFeatureCard(
                              context: context,
                              title: 'උපදෙස් සහ ඉඟි',
                              description: 'බුලත් වගාව පිළිබඳ විශේෂඥ උපදෙස්',
                              iconData: Icons.lightbulb,
                              color: Colors.purple.shade200,
                              imagePath: 'assets/images/tips.png',
                              onTap: () {
                                // Navigate to tips screen
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            // Quick Stats Section
                            _buildQuickStatsSection(context),
                            
                            // Add more space at the bottom
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final currentTime = TimeOfDay.now().hour;
    String greeting = 'සුභ දවසක්';
    
    if (currentTime < 12) {
      greeting = 'සුභ උදෑසනක්';
    } else if (currentTime < 17) {
      greeting = 'සුභ දහවලක්';
    } else {
      greeting = 'සුභ සන්ධ්‍යාවක්';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'සරංග',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ඔබගේ බුලත් පඳුරු ඵලදායී ලෙස කළමනාකරණය කරන්න',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
    double height = 110, // Default height with option to override
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
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
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context) {
    // Get data from provider
    final betelBedProvider = Provider.of<BetelBedProvider>(context);
    
    // Calculate stats
    final totalBeds = betelBedProvider.totalBeds;
    final bedsNeedingAttention = betelBedProvider.bedsNeedingAttention;
    final totalPlants = betelBedProvider.totalPlants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'සාරාංශය',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'මුළු පඳුරු',
                value: totalBeds.toString(),
                iconData: Icons.spa,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'අවධානය අවශ්‍ය',
                value: bedsNeedingAttention.toString(),
                iconData: Icons.warning_amber,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'මුළු පැළ',
                value: totalPlants.toString(),
                iconData: Icons.eco,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            iconData,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
