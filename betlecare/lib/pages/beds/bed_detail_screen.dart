import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/edit_bed_screen.dart';

class BedDetailScreen extends StatefulWidget {
  final BetelBed bed;

  const BedDetailScreen({super.key, required this.bed});

  @override
  State<BedDetailScreen> createState() => _BedDetailScreenState();
}

class _BedDetailScreenState extends State<BedDetailScreen> {
  late BetelBed bed;

  @override
  void initState() {
    super.initState();
    bed = widget.bed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                bed.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    bed.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.green.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBedScreen(bed: bed),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showMoreOptions();
                },
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(),
                
                // Details Section
                _buildDetailsSection(),
                
                // Action Cards
                _buildActionCards(),
                
                // History Sections
                _buildHistorySection('පොහොර යෙදීම් ඉතිහාසය', Icons.water_drop, bed.fertilizeHistory.isEmpty),
                if (bed.fertilizeHistory.isNotEmpty)
                  _buildFertilizeHistoryList(),
                  
                _buildHistorySection('අස්වනු ඉතිහාසය', Icons.shopping_basket, bed.harvestHistory.isEmpty),
                if (bed.harvestHistory.isNotEmpty)
                  _buildHarvestHistoryList(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickActionMenu();
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCard() {
    // Set color based on bed status
    Color statusColor;
    IconData statusIcon;
    String statusText = bed.nextAction;
    
    switch (bed.status) {
      case BetelBedStatus.needsFertilizing:
        statusColor = Colors.orange;
        statusIcon = Icons.water_drop;
        break;
      case BetelBedStatus.readyToHarvest:
        statusColor = Colors.green.shade700;
        statusIcon = Icons.shopping_basket;
        break;
      case BetelBedStatus.needsWatering:
        statusColor = Colors.blue;
        statusIcon = Icons.water;
        break;
      case BetelBedStatus.diseased:
        statusColor = Colors.red;
        statusIcon = Icons.healing;
        break;
      default:
        statusColor = Colors.teal;
        statusIcon = Icons.check_circle;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
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
    );
  }

  String _getStatusDescription() {
    switch (bed.status) {
      case BetelBedStatus.needsFertilizing:
        return 'ඉදිරි දින ${bed.daysUntilNextFertilizing.abs()} තුළ පොහොර යෙදිය යුතුයි';
      case BetelBedStatus.readyToHarvest:
        return 'අස්වනු නෙලීමට සූදානම්. ඉදිරි දින 2ක් තුළ අස්වනු නෙලන්න';
      case BetelBedStatus.needsWatering:
        return 'පැළවලට ජලය අවශ්‍ය වෙයි';
      case BetelBedStatus.recentlyFertilized:
        return 'පසුගිය දින ${bed.daysUntilNextFertilizing + 30} කදී පොහොර යොදා ඇත';
      case BetelBedStatus.recentlyHarvested:
        return 'තව දින ${bed.daysUntilNextHarvesting}කින් නැවත අස්වනු නෙළිය හැක';
      case BetelBedStatus.diseased:
        return 'රෝග ලක්ෂණ දක්නට ලැබේ. ඉක්මනින් ප්‍රතිකාර කරන්න';
      case BetelBedStatus.healthy:
      default:
        return 'පැළ හොඳ තත්වයේ පවතී';
    }
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'විස්තර',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailItem(Icons.spa, 'බුලත් වර්ගය', bed.betelType),
          _buildDetailItem(Icons.calendar_today, 'වගා කළ දිනය', 
              '${bed.plantedDate.year}-${bed.plantedDate.month.toString().padLeft(2, '0')}-${bed.plantedDate.day.toString().padLeft(2, '0')}'),
          _buildDetailItem(Icons.timer, 'වයස', '${bed.ageInDays} දින'),
          _buildDetailItem(Icons.straighten, 'ප්‍රමාණය', '${bed.areaSize} m²'),
          _buildDetailItem(Icons.grass, 'පැළ ගණන', bed.plantCount.toString()),
          _buildDetailItem(Icons.location_on, 'ස්ථානය', bed.location),
          _buildDetailItem(Icons.grid_view, 'සමාන පඳුරු ගණන', bed.sameBedCount.toString()),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Fertilize Action Card
          Expanded(
            child: _buildActionCard(
              title: 'පොහොර යෙදීම',
              icon: Icons.water_drop,
              color: Colors.blue,
              onTap: () {
                // Show add fertilize dialog
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Harvest Action Card
          Expanded(
            child: _buildActionCard(
              title: 'අස්වනු නෙලීම',
              icon: Icons.shopping_basket,
              color: Colors.green.shade700,
              onTap: () {
                // Show add harvest dialog
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(String title, IconData icon, bool isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'තවම වාර්තා කර නැත',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFertilizeHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bed.fertilizeHistory.length,
      itemBuilder: (context, index) {
        final record = bed.fertilizeHistory[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.water_drop, color: Colors.blue.shade700, size: 18),
          ),
          title: Text(record.fertilizerType),
          subtitle: Text(
            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')} • ${record.quantity}kg',
          ),
          trailing: record.notes.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    // Show notes in dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('සටහන'),
                        content: Text(record.notes),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('හරි'),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildHarvestHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bed.harvestHistory.length,
      itemBuilder: (context, index) {
        final harvest = bed.harvestHistory[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.shopping_basket, color: Colors.green.shade700, size: 18),
          ),
          title: Text('${harvest.leavesCount} කොළ • ${harvest.weight}kg'),
          subtitle: Text(
            '${harvest.date.year}-${harvest.date.month.toString().padLeft(2, '0')}-${harvest.date.day.toString().padLeft(2, '0')} • රු.${harvest.revenueEarned.toStringAsFixed(2)}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              harvest.quality,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('සංස්කරණය කරන්න'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBedScreen(bed: bed),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('පිටපත් කරන්න'),
              onTap: () {
                Navigator.pop(context);
                // Clone bed logic
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade700),
              title: Text('මකන්න', style: TextStyle(color: Colors.red.shade700)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'ක්‍රියාමාර්ග',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.blue),
              title: const Text('පොහොර යෙදීමක් එක් කරන්න'),
              onTap: () {
                Navigator.pop(context);
                // Show add fertilize dialog/screen
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_basket, color: Colors.green.shade700),
              title: const Text('අස්වැන්නක් එක් කරන්න'),
              onTap: () {
                Navigator.pop(context);
                // Show add harvest dialog/screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.amber),
              title: const Text('ප්‍රශ්නයක් වාර්තා කරන්න'),
              onTap: () {
                Navigator.pop(context);
                // Show report issue dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('සටහනක් එක් කරන්න'),
              onTap: () {
                Navigator.pop(context);
                // Show add note dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('පඳුර මකන්නද?'),
        content: const Text(
          'මෙම බුලත් පඳුර සහ එයට අදාළ සියලුම දත්ත මකා දැමෙනු ඇත. මෙය ආපසු හැරවිය නොහැක.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to beds list
              // Delete bed logic would go here
            },
            child: Text(
              'මකන්න',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}