import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/bed_detail_screen.dart';
import 'package:betlecare/pages/beds/add_new_bed_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:betlecare/services/wateringService.dart';
import 'package:betlecare/widgets/weather/WateringRecommendationWidget.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:betlecare/widgets/weather/FertilizingRecommendationWidget.dart';
class MyBedsScreen extends StatefulWidget {
  const MyBedsScreen({super.key});

  @override
  State<MyBedsScreen> createState() => _MyBedsScreenState();
}

class _MyBedsScreenState extends State<MyBedsScreen> {
  late Future<List<BetelBed>> _bedsFuture;
  final _betelBedService = BetelBedService();
  final _wateringService = WateringService();
  bool _isLoading = false;
  
  // Map to store watering recommendations for each bed
  final Map<String, Map<String, dynamic>> _wateringRecommendations = {};

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
        title: const Text('මගේ බුලත් වගාවන්', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBeds)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBeds,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildAddNewBedButton(),
            ),
            _isLoading
                ? SliverFillRemaining(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.network(
                              "https://lottie.host/08fd21f4-4d0f-4ddd-a7a6-9434caa397b6/lykm1jOaUY.json",
                              fit: BoxFit.cover,
                              width: 150,
                              height: 70,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildSliverBedsList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onTabChange: (index) {
          if (index != 2) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildAddNewBedButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewBedScreen()),
          );
          if (result == true) _loadBeds();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.green.shade300, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 24, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'නව බුලත් පඳුරක් එකතු කරන්න',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBedsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: FutureBuilder<List<BetelBed>>(
        future: _bedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverFillRemaining(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.network(
                        "https://lottie.host/08fd21f4-4d0f-4ddd-a7a6-9434caa397b6/lykm1jOaUY.json",
                        fit: BoxFit.cover,
                        width: 150,
                        height: 70,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return SliverFillRemaining(
              child: _buildErrorState(),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(),
            );
          }
          
          final beds = snapshot.data!;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildBedCard(beds[index]),
                );
              },
              childCount: beds.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('දත්ත ලබා ගැනීමේ දෝෂයකි', style: TextStyle(color: Colors.red[700])),
          TextButton(onPressed: _loadBeds, child: const Text('නැවත උත්සාහ කරන්න')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'තවම බුලත් වගාවන් නැත',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ඔබගේ පළමු බුලත් පඳුර එකතු කිරීමට ඉහත බොත්තම ක්ලික් කරන්න',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Modified method in MyBedsScreen to properly handle navigation to BedDetailScreen with result
Widget _buildBedCard(BetelBed bed) {
  final statusColor = _getStatusColor(bed.status);
  
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: statusColor.withOpacity(0.3)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => BedDetailScreen(bed: bed))
        );
        
        // If result is true (bed was updated or deleted), refresh the list
        if (result == true) {
          _loadBeds();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBedCardHeader(bed, statusColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBedCardTitle(bed),
                const SizedBox(height: 8),
                _buildBedCardLocation(bed),
                const SizedBox(height: 16),
                _buildBedCardStats(bed),
                const Divider(height: 32),
                _buildBedCardActions(bed),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBedCardHeader(BetelBed bed, Color statusColor) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              bed.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bed.nextAction,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBedCardTitle(BetelBed bed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            bed.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildBedCardLocation(BetelBed bed) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                bed.district,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.home, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                bed.address,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBedCardStats(BetelBed bed) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBedStat(icon: Icons.spa, label: 'බුලත් වර්ගය', value: bed.betelType),
          _buildBedStat(icon: Icons.grass, label: 'පැළ ගණන', value: bed.plantCount.toString()),
          _buildBedStat(icon: Icons.straighten, label: 'ප්‍රමාණය', value: '${bed.areaSize} m²'),
        ],
      ),
    );
  }

Widget _buildBedCardActions(BetelBed bed) {
  return Column(
    children: [
      // Watering recommendation widget
      SizedBox(
        width: double.infinity,
        child: WateringRecommendationWidget(bed: bed),
      ),
      const SizedBox(height: 8), // Add a small gap
      
      // Fertilizing recommendation widget - Add this new part
      SizedBox(
        width: double.infinity,
        child: FertilizingRecommendationWidget(bed: bed),
      ),
      const SizedBox(height: 16),
      
      // Action buttons
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.water_drop,
            label: 'පොහොර',
            onTap: () => _showFertilizeHistory(bed),
          ),
          _buildActionButton(
            icon: Icons.shopping_basket,
            label: 'අස්වනු',
            onTap: () => _showHarvestHistory(bed),
          ),
          _buildActionButton(
            icon: Icons.more_horiz,
            label: 'තවත්',
            onTap: () => _showStatusUpdateDialog(bed),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildBedStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label, 
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BetelBedStatus status) {
    switch (status) {
      case BetelBedStatus.needsFertilizing: return Colors.orange;
      case BetelBedStatus.readyToHarvest: return Colors.green.shade600;
      case BetelBedStatus.needsWatering: return Colors.blue;
      case BetelBedStatus.diseased: return Colors.red;
      default: return Colors.teal;
    }
  }

  void _showFertilizeHistory(BetelBed bed) {
    _showHistoryBottomSheet(
      bed: bed,
      title: '${bed.name} - පොහොර ඉතිහාසය',
      historyItems: bed.fertilizeHistory,
      emptyText: 'පොහොර යෙදීමේ ඉතිහාසයක් නොමැත',
      buttonText: 'නව පොහොර යෙදීමක් එක් කරන්න',
      onAddPressed: () {
        Navigator.pop(context);
        _showAddFertilizeDialog(bed);
      },
      itemBuilder: (record) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.water_drop, color: Colors.white, size: 18),
        ),
        title: Text(
          record.fertilizerType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(record.date)} • ${record.quantity}kg',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${DateTime.now().difference(record.date).inDays} දින පෙර',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  void _showHarvestHistory(BetelBed bed) {
    _showHistoryBottomSheet(
      bed: bed,
      title: '${bed.name} - අස්වනු ඉතිහාසය',
      historyItems: bed.harvestHistory,
      emptyText: 'අස්වනු නෙලීමේ ඉතිහාසයක් නොමැත',
      buttonText: 'නව අස්වැන්නක් එක් කරන්න',
      onAddPressed: () {
        Navigator.pop(context);
        _showAddHarvestDialog(bed);
      },
      itemBuilder: (harvest) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.shopping_basket, color: Colors.white, size: 18),
        ),
        title: Text(
          '${harvest.leavesCount} කොළ • ${harvest.weight}kg',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(harvest.date)} • රු.${harvest.revenueEarned.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  void _showHistoryBottomSheet<T>({
    required BetelBed bed,
    required String title,
    required List<T> historyItems,
    required String emptyText,
    required String buttonText,
    required VoidCallback onAddPressed,
    required Widget Function(T) itemBuilder,
  }) {
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
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Divider(),
            Expanded(
              child: historyItems.isEmpty
                  ? Center(child: Text(emptyText, style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) => itemBuilder(historyItems[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onAddPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

void _showAddFertilizeDialog(BetelBed bed) {
  final dateController = TextEditingController(text: _getTodayFormatted());
  // Remove the typeController as we'll use the dropdown value directly
  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  
  // Define fertilizer types mapping (Sinhala to English)
  final Map<String, String> fertilizerTypes = {
    'ග්ලිරිසීඩියා කොල': 'Gliricidia leaves',
    'ගොම පොහොර': 'Cow dung',
    'NPK 10 අනුපාතයට': 'Balanced NPK (10-10-10)',
    'කුකුල් පොහොර': 'Poultry manure',
    'කොම්පෝස්ට්': 'Compost',
  };
  
  // Initial selection
  String selectedFertilizerSinhala = 'ග්ලිරිසීඩියා කොල'; // Default selection
  
  _showFormDialog(
    title: 'නව පොහොර යෙදීමක් එක් කරන්න',
    fields: [
      _buildDateField(dateController),
      // Replace TextField with DropdownButtonFormField
      DropdownButtonFormField<String>(
        value: selectedFertilizerSinhala,
        decoration: const InputDecoration(labelText: 'පොහොර වර්ගය'),
        items: fertilizerTypes.keys.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            selectedFertilizerSinhala = newValue;
          }
        },
      ),
      TextField(
        controller: quantityController,
        decoration: const InputDecoration(labelText: 'ප්‍රමාණය (kg)'),
        keyboardType: TextInputType.number,
      ),
      TextField(
        controller: notesController,
        decoration: const InputDecoration(labelText: 'සටහන්'),
        maxLines: 2,
      ),
    ],
    onSave: () async {
      try {
        if (selectedFertilizerSinhala.isEmpty || quantityController.text.isEmpty) {
          _showErrorSnackBar('කරුණාකර අවශ්‍ය තොරතුරු පුරවන්න');
          return;
        }
        
        final quantity = double.tryParse(quantityController.text);
        if (quantity == null) {
          _showErrorSnackBar('වලංගු ප්‍රමාණයක් ඇතුළත් කරන්න');
          return;
        }
        
        final date = DateTime.parse(dateController.text);
        
        // Convert Sinhala fertilizer type to English for backend
        final englishFertilizerType = fertilizerTypes[selectedFertilizerSinhala] ?? selectedFertilizerSinhala;
        
        final record = FertilizeRecord(
          date: date,
          fertilizerType: englishFertilizerType, // Send English name to backend
          quantity: quantity,
          notes: notesController.text,
        );
        
        await _betelBedService.addFertilizeRecord(bed.id, record);
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('පොහොර යෙදීම සාර්ථකව එකතු කරන ලදී')),
        );
        
        _loadBeds();
      } catch (e) {
        _showErrorSnackBar('දෝෂයකි: ${e.toString()}');
      }
    },
  );
}

  void _showAddHarvestDialog(BetelBed bed) {
    final dateController = TextEditingController(text: _getTodayFormatted());
    final leavesController = TextEditingController();
    final weightController = TextEditingController();
    final revenueController = TextEditingController();
    final qualityController = TextEditingController(text: 'A');
    final notesController = TextEditingController();
    
    final qualities = ['A', 'B', 'C', 'D'];
    
    _showFormDialog(
      title: 'නව අස්වැන්නක් එක් කරන්න',
      fields: [
        _buildDateField(dateController),
        TextField(
          controller: leavesController,
          decoration: const InputDecoration(labelText: 'කොළ ගණන'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: weightController,
          decoration: const InputDecoration(labelText: 'බර (kg)'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: revenueController,
          decoration: const InputDecoration(labelText: 'ආදායම (රු.)'),
          keyboardType: TextInputType.number,
        ),
        DropdownButtonFormField<String>(
          value: qualityController.text,
          decoration: const InputDecoration(labelText: 'තත්ත්වය'),
          items: qualities.map((quality) => DropdownMenuItem<String>(
            value: quality,
            child: Text(quality),
          )).toList(),
          onChanged: (value) => qualityController.text = value!,
        ),
        TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'සටහන්'),
          maxLines: 2,
        ),
      ],
      onSave: () async {
        try {
          if (leavesController.text.isEmpty || weightController.text.isEmpty || revenueController.text.isEmpty) {
            _showErrorSnackBar('කරුණාකර අවශ්‍ය තොරතුරු පුරවන්න');
            return;
          }
          
          final leaves = int.tryParse(leavesController.text);
          final weight = double.tryParse(weightController.text);
          final revenue = double.tryParse(revenueController.text);
          
          if (leaves == null || weight == null || revenue == null) {
            _showErrorSnackBar('වලංගු අගයන් ඇතුළත් කරන්න');
            return;
          }
          
          final date = DateTime.parse(dateController.text);
          
          final record = HarvestRecord(
            date: date,
            leavesCount: leaves,
            weight: weight,
            revenueEarned: revenue,
            quality: qualityController.text,
            notes: notesController.text,
          );
          
          await _betelBedService.addHarvestRecord(bed.id, record);
          
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('අස්වැන්න සාර්ථකව එකතු කරන ලදී')),
          );
          
          _loadBeds();
        } catch (e) {
          _showErrorSnackBar('දෝෂයකි: ${e.toString()}');
        }
      },
    );
  }

  Widget _buildDateField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'දිනය (YYYY-MM-DD)'),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        
        if (date != null) {
          controller.text = _formatDate(date);
        }
      },
    );
  }

  void _showFormDialog({
    required String title,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('සුරකින්න'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BetelBed bed) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          '${bed.name} - තත්ත්වය යාවත්කාලීන කරන්න',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('තත්ත්වය යාවත්කාලීන කරමින්...')),
          );
          
          await _betelBedService.updateBedStatus(bed.id, status);
          _loadBeds();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('තත්ත්වය සාර්ථකව යාවත්කාලීන කරන ලදී')),
          );
       } catch (e) {
          _showErrorSnackBar('දෝෂයකි: ${e.toString()}');
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) => 
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  String _getTodayFormatted() => _formatDate(DateTime.now());
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}