import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/edit_bed_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';

class BedDetailScreen extends StatefulWidget {
  final BetelBed bed;

  const BedDetailScreen({super.key, required this.bed});

  @override
  State<BedDetailScreen> createState() => _BedDetailScreenState();
}

class _BedDetailScreenState extends State<BedDetailScreen> {
  late BetelBed bed;
  bool _isLoading = false;
  final _betelBedService = BetelBedService();

  @override
  void initState() {
    super.initState();
    bed = widget.bed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                      Image.network(
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.green.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
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
                      ).then((_) {
                        // Refresh data when returning from edit screen
                        _refreshBedData();
                      });
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
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
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

  Future<void> _refreshBedData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get updated bed data from provider or service
      final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
      
      // Reload all beds
      await betelBedProvider.loadBeds();
      
      // Find the current bed in the updated list
      final updatedBed = betelBedProvider.beds.firstWhere(
        (b) => b.id == bed.id,
        orElse: () => bed,
      );
      
      setState(() {
        bed = updatedBed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දත්ත යාවත්කාලීන කිරීමේ දෝෂයකි: ${e.toString()}')),
      );
    }
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
                _showAddFertilizeDialog();
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
                _showAddHarvestDialog();
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
    // Sort by date (newest first)
    final sortedHistory = List<FertilizeRecord>.from(bed.fertilizeHistory);
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      itemBuilder: (context, index) {
        final record = sortedHistory[index];
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
    // Sort by date (newest first)
    final sortedHistory = List<HarvestRecord>.from(bed.harvestHistory);
    sortedHistory.sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      itemBuilder: (context, index) {
        final harvest = sortedHistory[index];
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
                ).then((_) {
                  _refreshBedData();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('තත්ත්වය යාවත්කාලීන කරන්න'),
              onTap: () {
                Navigator.pop(context);
                _showStatusUpdateDialog();
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

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${bed.name} - තත්ත්වය යාවත්කාලීන කරන්න'),
        children: [
          _buildStatusOption(
            status: BetelBedStatus.healthy,
            title: 'හොඳ තත්ත්වයේ පවතී',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatusOption(
            status: BetelBedStatus.needsWatering,
            title: 'ජලය යෙදීම අවශ්‍යයි',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
          _buildStatusOption(
            status: BetelBedStatus.needsFertilizing,
            title: 'පොහොර යෙදීම අවශ්‍යයි',
            icon: Icons.grass,
            color: Colors.orange,
          ),
          _buildStatusOption(
            status: BetelBedStatus.readyToHarvest,
            title: 'අස්වනු නෙලීමට සූදානම්',
            icon: Icons.shopping_basket,
            color: Colors.green.shade700,
          ),
          _buildStatusOption(
            status: BetelBedStatus.diseased,
            title: 'රෝගී තත්වයේ පවතී',
            icon: Icons.sick,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusOption({
    required BetelBedStatus status,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return SimpleDialogOption(
      onPressed: () async {
        try {
          Navigator.pop(context);
          
          setState(() {
            _isLoading = true;
          });
          
          // Update status
          await _betelBedService.updateBedStatus(bed.id, status);
          
          // Refresh data
          await _refreshBedData();
          
          // Show success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('තත්ත්වය සාර්ථකව යාවත්කාලීන කරන ලදී')),
          );
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('දෝෂයකි: ${e.toString()}')),
          );
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(title),
        ],
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
                _showAddFertilizeDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_basket, color: Colors.green.shade700),
              title: const Text('අස්වැන්නක් එක් කරන්න'),
              onTap: () {
                Navigator.pop(context);
                _showAddHarvestDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.update, color: Colors.teal),
              title: const Text('තත්ත්වය යාවත්කාලීන කරන්න'),
              onTap: () {
                Navigator.pop(context);
                _showStatusUpdateDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFertilizeDialog() {
    final dateController = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    final typeController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('නව පොහොර යෙදීමක් එක් කරන්න'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'දිනය (YYYY-MM-DD)',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  
                  if (date != null) {
                    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'පොහොර වර්ගය',
                ),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'ප්‍රමාණය (kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'සටහන්',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Validate inputs
                if (typeController.text.isEmpty || quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('කරුණාකර අවශ්‍ය තොරතුරු පුරවන්න')),
                  );
                  return;
                }
                
                final quantity = double.tryParse(quantityController.text);
                if (quantity == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('වලංගු ප්‍රමාණයක් ඇතුළත් කරන්න')),
                  );
                  return;
                }
                
                // Parse date
                final date = DateTime.parse(dateController.text);
                
                // Create record
                final record = FertilizeRecord(
                  date: date,
                  fertilizerType: typeController.text,
                  quantity: quantity,
                  notes: notesController.text,
                );
                
                // Close dialog
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });
                
                // Save to Supabase
                await _betelBedService.addFertilizeRecord(bed.id, record);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('පොහොර යෙදීම සාර්ථකව එකතු කරන ලදී')),
                );
                
                // Reload bed data
                await _refreshBedData();
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('දෝෂයකි: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('සුරකින්න'),
          ),
        ],
      ),
    );
  }

  void _showAddHarvestDialog() {
    final dateController = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    final leavesController = TextEditingController();
    final weightController = TextEditingController();
    final revenueController = TextEditingController();
    final qualityController = TextEditingController(text: 'A');
    final notesController = TextEditingController();
    
    final qualities = ['A', 'B', 'C', 'D'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('නව අස්වැන්නක් එක් කරන්න'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'දිනය (YYYY-MM-DD)',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  
                  if (date != null) {
                    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              TextField(
                controller: leavesController,
                decoration: const InputDecoration(
                  labelText: 'කොළ ගණන',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'බර (kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: revenueController,
                decoration: const InputDecoration(
                  labelText: 'ආදායම (රු.)',
                ),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: qualityController.text,
                decoration: const InputDecoration(
                  labelText: 'තත්ත්වය',
                ),
                items: qualities.map((quality) {
                  return DropdownMenuItem<String>(
                    value: quality,
                    child: Text(quality),
                  );
                }).toList(),
                onChanged: (value) {
                  qualityController.text = value!;
                },
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'සටහන්',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Validate inputs
                if (leavesController.text.isEmpty || 
                    weightController.text.isEmpty || 
                    revenueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('කරුණාකර අවශ්‍ය තොරතුරු පුරවන්න')),
                  );
                  return;
                }
                
                final leaves = int.tryParse(leavesController.text);
                final weight = double.tryParse(weightController.text);
                final revenue = double.tryParse(revenueController.text);
                
                if (leaves == null || weight == null || revenue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('වලංගු අගයන් ඇතුළත් කරන්න')),
                  );
                  return;
                }
                
                // Parse date
                final date = DateTime.parse(dateController.text);
                
                // Create record
                final record = HarvestRecord(
                  date: date,
                  leavesCount: leaves,
                  weight: weight,
                  revenueEarned: revenue,
                  quality: qualityController.text,
                  notes: notesController.text,
                );
                
                // Close dialog
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });
                
                // Save to Supabase
                await _betelBedService.addHarvestRecord(bed.id, record);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('අස්වැන්න සාර්ථකව එකතු කරන ලදී')),
                );
                
                // Reload bed data
                await _refreshBedData();
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('දෝෂයකි: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('සුරකින්න'),
          ),
        ],
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
            onPressed: () async {
              try {
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });
                
                // Delete bed from Supabase
                final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
                await betelBedProvider.deleteBed(bed.id);
                
                setState(() {
                  _isLoading = false;
                });
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('බුලත් පඳුර සාර්ථකව මකා දමන ලදී')),
                );
                
                // Go back to beds list
                Navigator.pop(context);
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('දෝෂයකි: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('මකන්න'),
          ),
        ],
      ),
    );
  }
}