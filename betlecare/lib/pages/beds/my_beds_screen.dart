import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/bed_detail_screen.dart';
import 'package:betlecare/pages/beds/add_new_bed_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';

class MyBedsScreen extends StatefulWidget {
  const MyBedsScreen({super.key});

  @override
  State<MyBedsScreen> createState() => _MyBedsScreenState();
}

class _MyBedsScreenState extends State<MyBedsScreen> {
  late Future<List<BetelBed>> _bedsFuture;
  final _betelBedService = BetelBedService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBeds();
  }

  Future<void> _loadBeds() async {
    setState(() {
      _isLoading = true;
      _bedsFuture = _betelBedService.getBetelBeds();
    });
    
    await _bedsFuture;
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'මගේ බුලත් පඳුරු',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBeds,
          ),
        ],
      ),
      body: Column(
        children: [
          // Add New Bed Button
          _buildAddNewBedButton(),
          
          // Beds List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<BetelBed>>(
                    future: _bedsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'දත්ත ලබා ගැනීමේ දෝෂයකි',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                              TextButton(
                                onPressed: _loadBeds,
                                child: const Text('නැවත උත්සාහ කරන්න'),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      final beds = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: beds.length,
                        itemBuilder: (context, index) {
                          return _buildBedCard(beds[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewBedButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddNewBedScreen(),
          ),
        );
        
        if (result == true) {
          // Refresh the list if a new bed was added
          _loadBeds();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              size: 24,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'නව බුලත් පඳුරක් එකතු කරන්න',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'තවම බුලත් පඳුරු නැත',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ඔබගේ පළමු බුලත් පඳුර එකතු කිරීමට ඉහත බොත්තම ක්ලික් කරන්න',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBedStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.green.shade700),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showFertilizeHistory(BetelBed bed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${bed.name} - පොහොර ඉතිහාසය',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: bed.fertilizeHistory.isEmpty
                  ? Center(
                      child: Text(
                        'පොහොර යෙදීමේ ඉතිහාසයක් නොමැත',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: bed.fertilizeHistory.length,
                      itemBuilder: (context, index) {
                        final record = bed.fertilizeHistory[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.water_drop, color: Colors.white, size: 18),
                          ),
                          title: Text(record.fertilizerType),
                          subtitle: Text(
                            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')} • ${record.quantity}kg',
                          ),
                          trailing: Text(
                            '${DateTime.now().difference(record.date).inDays} දින පෙර',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Show dialog to add fertilize record
                  _showAddFertilizeDialog(bed);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('නව පොහොර යෙදීමක් එක් කරන්න'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFertilizeDialog(BetelBed bed) {
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
                
                // Save to Supabase
                await _betelBedService.addFertilizeRecord(bed.id, record);
                
                // Close dialog
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('පොහොර යෙදීම සාර්ථකව එකතු කරන ලදී')),
                );
                
                // Reload beds
                _loadBeds();
              } catch (e) {
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

  void _showHarvestHistory(BetelBed bed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${bed.name} - අස්වනු ඉතිහාසය',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: bed.harvestHistory.isEmpty
                  ? Center(
                      child: Text(
                        'අස්වනු නෙලීමේ ඉතිහාසයක් නොමැත',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: bed.harvestHistory.length,
                      itemBuilder: (context, index) {
                        final harvest = bed.harvestHistory[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade700,
                            child: const Icon(Icons.shopping_basket, color: Colors.white, size: 18),
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
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Show dialog to add harvest record
                  _showAddHarvestDialog(bed);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('නව අස්වැන්නක් එක් කරන්න'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHarvestDialog(BetelBed bed) {
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
                
                // Save to Supabase
                await _betelBedService.addHarvestRecord(bed.id, record);
                
                // Close dialog
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('අස්වැන්න සාර්ථකව එකතු කරන ලදී')),
                );
                
                // Reload beds
                _loadBeds();
              } catch (e) {
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

  Widget _buildBedCard(BetelBed bed) {
    // Determine card accent color based on status
    Color statusColor;
    switch (bed.status) {
      case BetelBedStatus.needsFertilizing:
        statusColor = Colors.orange;
        break;
      case BetelBedStatus.readyToHarvest:
        statusColor = Colors.green.shade600;
        break;
      case BetelBedStatus.needsWatering:
        statusColor = Colors.blue;
        break;
      case BetelBedStatus.diseased:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.teal;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BedDetailScreen(bed: bed),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    bed.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
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
                ),
                // Status tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bed.nextAction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bed.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${bed.ageInDays} දින',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bed.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBedStat(
                        icon: Icons.spa,
                        label: 'බුලත් වර්ගය',
                        value: bed.betelType,
                      ),
                      _buildBedStat(
                        icon: Icons.grass,
                        label: 'පැළ ගණන',
                        value: bed.plantCount.toString(),
                      ),
                      _buildBedStat(
                        icon: Icons.straighten,
                        label: 'ප්‍රමාණය',
                        value: '${bed.areaSize} m²',
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.water_drop,
                        label: 'පොහොර',
                        onTap: () {
                          // Show fertilize history/action
                          _showFertilizeHistory(bed);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.shopping_basket,
                        label: 'අස්වනු',
                        onTap: () {
                          // Show harvest history/action
                          _showHarvestHistory(bed);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.more_horiz,
                        label: 'තවත්',
                        onTap: () {
                          // Show more options
                          _showStatusUpdateDialog(bed);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showStatusUpdateDialog(BetelBed bed) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${bed.name} - තත්ත්වය යාවත්කාලීන කරන්න'),
        children: [
          _buildStatusOption(
            bed: bed,
            status: BetelBedStatus.healthy,
            title: 'හොඳ තත්ත්වයේ පවතී',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatusOption(
            bed: bed,
            status: BetelBedStatus.needsWatering,
            title: 'ජලය යෙදීම අවශ්‍යයි',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
          _buildStatusOption(
            bed: bed,
            status: BetelBedStatus.needsFertilizing,
            title: 'පොහොර යෙදීම අවශ්‍යයි',
            icon: Icons.grass,
            color: Colors.orange,
          ),
          _buildStatusOption(
            bed: bed,
            status: BetelBedStatus.readyToHarvest,
            title: 'අස්වනු නෙලීමට සූදානම්',
            icon: Icons.shopping_basket,
            color: Colors.green.shade700,
          ),
          _buildStatusOption(
            bed: bed,
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
    required BetelBed bed,
    required BetelBedStatus status,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return SimpleDialogOption(
      onPressed: () async {
        try {
          Navigator.pop(context);
          
          // Show loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('තත්ත්වය යාවත්කාලීන කරමින්...')),
          );
          
          // Update status
          await _betelBedService.updateBedStatus(bed.id, status);
          
          // Reload beds
          _loadBeds();
          
          // Show success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('තත්ත්වය සාර්ථකව යාවත්කාලීන කරන ලදී')),
          );
        } catch (e) {
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
}