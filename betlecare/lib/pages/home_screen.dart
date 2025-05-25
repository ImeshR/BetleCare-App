import 'package:betlecare/pages/home/tips_and_advice.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/my_beds_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:betlecare/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

// Enhanced HarvestService class to fetch all lands and specific land data
class HarvestService {
  final supabase = Supabase.instance.client;

  // Fetch all unique lands for a user
  Future<List<Map<String, dynamic>>> getUserLands(String? userId) async {
    if (userId == null) {
      throw Exception("User ID is null");
    }

    try {
      // Query to get all unique lands for this user
      final response = await supabase
          .from('harvest_monitor_history')
          .select('land_name, land_location, land_size')
          .eq('user_id', userId)
          .order('land_name');

      // Extract unique lands by name
      final List<Map<String, dynamic>> lands = [];
      final Set<String> landNames = {};

      for (var item in response as List) {
        if (!landNames.contains(item['land_name'])) {
          landNames.add(item['land_name']);
          lands.add({
            'land_name': item['land_name'],
            'land_location': item['land_location'],
            'land_size': item['land_size'],
          });
        }
      }

      return lands;
    } catch (e) {
      throw Exception("Failed to fetch user lands: $e");
    }
  }

  // Fetch latest harvest data for a specific land
  Future<Map<String, dynamic>?> getLatestHarvestDataForLand(
      String? userId, String landName) async {
    if (userId == null) {
      throw Exception("User ID is null");
    }

    try {
      // Query the latest harvest record for this user and land
      final response = await supabase
          .from('harvest_monitor_history')
          .select('*')
          .eq('user_id', userId)
          .eq('land_name', landName)
          .order('harvest_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception("Failed to fetch harvest data: $e");
    }
  }

  // Original method to get latest harvest data (any land)
  Future<Map<String, dynamic>?> getLatestHarvestData(String? userId) async {
    if (userId == null) {
      throw Exception("User ID is null");
    }

    try {
      // Query the latest harvest record for this user
      final response = await supabase
          .from('harvest_monitor_history')
          .select('*')
          .eq('user_id', userId)
          .order('harvest_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null; // No harvest data found
      }

      return response;
    } catch (e) {
      throw Exception("Failed to fetch harvest data: $e");
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  String? _selectedLandName;
  List<Map<String, dynamic>> _userLands = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // WhatsApp chatbot function
  Future<void> _openWhatsAppBot() async {
    const phoneNumber = '+14155238886';
    const message = 'join cast-add';
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp ඇප් එක විවෘත කිරීමට නොහැකි විය')),
      );
    }
  }

  Future<void> _loadData() async {
    final betelBedProvider =
        Provider.of<BetelBedProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await betelBedProvider.loadBeds();

      // Load user lands
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId != null) {
        final harvestService = HarvestService();
        final lands = await harvestService.getUserLands(userId);

        setState(() {
          _userLands = lands;
          // Set the first land as selected by default if available
          if (lands.isNotEmpty && _selectedLandName == null) {
            _selectedLandName = lands[0]['land_name'];
          }
        });
      }
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
            ? const Center(
                child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red[300]),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Card

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

                            // My Beds Card
                            _buildFeatureCard(
                              context: context,
                              title: 'මගේ බුලත් වගාවන්',
                              description: 'ඔබගේ බුලත් වගාවන් කළමනාකරණය කරන්න',
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

                            _buildFeatureCard(
                              context: context,
                              title: 'උපදෙස් සහ ඉඟි',
                              description: 'බුලත් වගාව පිළිබඳ විශේෂඥ උපදෙස්',
                              iconData: Icons.lightbulb,
                              color: Colors.purple.shade200,
                              imagePath: 'assets/images/tips.png',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TipsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // WhatsApp Chatbot Card
                            _buildFeatureCard(
                              context: context,
                              title: 'AI සහායක',
                              description: 'WhatsApp හරහා බුලත් ප්‍රශ්න අසන්න',
                              iconData: Icons.chat,
                              color: Colors.blue.shade200,
                              imagePath: 'assets/images/chat.png',
                              onTap: _openWhatsAppBot,
                            ),

                            const SizedBox(height: 16),
                            // Quick Stats Section
                            _buildQuickStatsSection(context),

                            const SizedBox(height: 16),
                            // Harvest Remind Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'අස්වනු සිහිකැඳවීම',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (_userLands.isNotEmpty) _buildLandSelector(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildHarvestRemindSection(context),

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

  // Land selector dropdown
  Widget _buildLandSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLandName,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
          ),
          isDense: true,
          hint: Text(
            'ඉඩම තෝරන්න',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          items: _userLands.map((land) {
            return DropdownMenuItem<String>(
              value: land['land_name'],
              child: Text(land['land_name']),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLandName = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHarvestRemindSection(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    // Fetch data from Supabase based on selected land
    final Future<Map<String, dynamic>?> futureHarvestData;

    if (_selectedLandName != null) {
      futureHarvestData = HarvestService()
          .getLatestHarvestDataForLand(userId, _selectedLandName!);
    } else {
      futureHarvestData = HarvestService().getLatestHarvestData(userId);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: futureHarvestData,
      builder: (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
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
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 32, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text(
                  'අසවනු දත්ත ලබා ගැනීමට නොහැකි විය',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  _selectedLandName != null
                      ? '"$_selectedLandName" සඳහා අසවනු දත්ත නොමැත'
                      : 'අසවනු දත්ත නොමැත',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'ඔබගේ පළමු අස්වැන්න සටහන් කරන්න',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'බුලත් වගාව සාමාන්‍යයෙන් සති 1-2 කාල පරාසයකින් අස්වනු ලබාගත හැකිය',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final lastHarvestDate = DateTime.parse(data['harvest_date'].toString());
        final landName = data['land_name'] as String;
        final landSize = double.tryParse(data['land_size'].toString()) ?? 0.0;
        final totalYield =
            double.tryParse(data['total_yield'].toString()) ?? 0.0;
        final pYield = double.tryParse(data['p_yield'].toString()) ?? 0.0;
        final ktYield = double.tryParse(data['kt_yield'].toString()) ?? 0.0;
        final rktYield = double.tryParse(data['rkt_yield'].toString()) ?? 0.0;
        final notes = data['notes'] as String?;
        final landLocation = data['land_location'] as String?;

        // Format the last harvest date
        final dateFormatter = DateFormat('yyyy/MM/dd');
        final formattedLastHarvestDate = dateFormatter.format(lastHarvestDate);

        // Land size > 1: 7-day cycle (harvesting happens in half-wise manner)
        // Land size < 1: 14-day cycle (due to small size)
        final harvestPeriod = landSize > 1 ? 7 : 14;
        final nextHarvestDate =
            lastHarvestDate.add(Duration(days: harvestPeriod));
        final formattedNextHarvestDate = dateFormatter.format(nextHarvestDate);

        // Calculate days remaining
        final daysRemaining = nextHarvestDate.difference(DateTime.now()).inDays;

        final cyclePeriodText = landSize > 1 ? 'දින 7 චක්‍රය' : 'දින 14 චක්‍රය';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.calendar_today,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ඊළඟ අස්වැන්න සිහිකැඳවීම',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ඔබගේ "$landName" ඉඩමේ ඊළඟ අස්වැන්න',
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
                ],
              ),

              // Land location if available
              if (landLocation != null && landLocation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        landLocation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Cultivation Cycle Badge
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: landSize > 1
                        ? Colors.teal.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: landSize > 1
                          ? Colors.teal.shade300
                          : Colors.blue.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 16,
                        color: landSize > 1
                            ? Colors.teal.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cyclePeriodText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: landSize > 1
                              ? Colors.teal.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Next harvest date and countdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ඊළඟ අස්වැන්න දිනය',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedNextHarvestDate,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: daysRemaining <= 3
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            daysRemaining <= 3
                                ? Icons.access_time_filled
                                : Icons.check_circle,
                            size: 16,
                            color: daysRemaining <= 3
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'තව දින $daysRemaining යි',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: daysRemaining <= 3
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cultivation cycle explanation
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      landSize > 1 ? Colors.teal.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: landSize > 1
                          ? Colors.teal.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        landSize > 1
                            ? 'ඔබ දැනට දින 7 අස්වනු චක්‍රයක සිටින්නේ ඉඩම් ප්‍රමාණය හෙක්ටයාර 1 ට වැඩි නිසා අර්ධ වශයෙන් අස්වනු නෙලා ගැනීමට හැකිය'
                            : 'ඔබ දැනට දින 14 අස්වනු චක්‍රයක සිටින්නේ ඉඩම් ප්‍රමාණය හෙක්ටයාර 1 ට අඩු නිසා අස්වනු නෙලීමට වැඩි කාලයක් ගතවේ',
                        style: TextStyle(
                          fontSize: 12,
                          color: landSize > 1
                              ? Colors.teal.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Last harvest details
              Text(
                'පසුගිය අස්වැන්න විස්තර',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),

              // Last harvest date
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'අස්වනු දිනය: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    formattedLastHarvestDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Land size
              Row(
                children: [
                  Icon(
                    Icons.crop_square,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ඉඩම් ප්‍රමාණය: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$landSize අක්කර',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Total yield
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'මුළු අස්වැන්න: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$totalYield ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Show yield breakdown if available
              if (pYield > 0 || ktYield > 0 || rktYield > 0) ...[
                const SizedBox(height: 12),

                // Yield breakdown
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'අස්වැන්න වර්ගීකරණය',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildYieldCategory('P', pYield, Colors.green),
                          _buildYieldCategory('KT', ktYield, Colors.orange),
                          _buildYieldCategory('RKT', rktYield, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Notes if available
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'සටහන්',
                            style: TextStyle
                            (
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                             color: Colors.blue[700],
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(
                       notes,
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.blue[800],
                       ),
                     ),
                   ],
                 ),
               ),
             ],

             // Betel cultivation tip
             const SizedBox(height: 12),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: Colors.amber.shade50,
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.amber.shade200),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(
                         Icons.lightbulb,
                         size: 14,
                         color: Colors.amber[700],
                       ),
                       const SizedBox(width: 4),
                       Text(
                         'බුලත් වගා ඉඟිය',
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                           color: Colors.amber[700],
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Text(
                     landSize > 1
                         ? 'විශාල ඉඩම් සඳහා දින 7 චක්‍රය වඩාත් සුදුසු වන අතර එය අර්ධ වශයෙන් අස්වනු නෙලා ගැනීමට හැකි වේ.'
                         : 'කුඩා ඉඩම් සඳහා දින 14 චක්‍රය වඩාත් සුදුසු වන අතර එය බුලත් කොළ වල ගුණාත්මක බව වැඩි කරයි.',
                     style: TextStyle(
                       fontSize: 11,
                       color: Colors.amber[800],
                     ),
                   ),
                 ],
               ),
             ),
           ],
         ),
       );
     },
   );
 }

 Widget _buildYieldCategory(String category, double yield, Color color) {
   return Column(
     children: [
       Container(
         width: 40,
         height: 40,
         decoration: BoxDecoration(
           color: color.withOpacity(0.2),
           shape: BoxShape.circle,
         ),
         child: Center(
           child: Text(
             category,
             style: TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
         ),
       ),
       const SizedBox(height: 4),
       Text(
         '$yield ',
         style: TextStyle(
           fontSize: 12,
           fontWeight: FontWeight.w500,
           color: Colors.grey[800],
         ),
       ),
     ],
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
   double height = 110,
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
   // get data from provider
   final betelBedProvider = Provider.of<BetelBedProvider>(context);

   // calculate stats
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
               title: 'මුළු වගාවන්',
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