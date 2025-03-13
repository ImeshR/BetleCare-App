import 'package:betlecare/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/beds/edit_bed_screen.dart';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:betlecare/widgets/weather/weeklyWateringRecomendation.dart';
import 'package:betlecare/widgets/weather/WeeklyFertilizingRecommendationWidget.dart';
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
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    _buildRecommendationsSection(),
                    _buildDetailsSection(),
                    _buildActionCards(),
                    _buildHistorySection('පොහොර යෙදීම් ඉතිහාසය', Icons.water_drop, bed.fertilizeHistory.isEmpty),
                    if (bed.fertilizeHistory.isNotEmpty) _buildFertilizeHistoryList(),
                    _buildHistorySection('අස්වනු ඉතිහාසය', Icons.shopping_basket, bed.harvestHistory.isEmpty),
                    if (bed.harvestHistory.isNotEmpty) _buildHarvestHistoryList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionMenu,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
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

Widget _buildRecommendationsSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tips_and_updates, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            const Text(
              ' නිර්දේශ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Weekly watering recommendation widget
        WeeklyWateringRecommendationWidget(bed: bed),
        
        const SizedBox(height: 16),
        
        // Fertilizing recommendation widget - replaced placeholder with actual widget
        WeeklyFertilizingRecommendationWidget(bed: bed),
        
        const SizedBox(height: 16),
        
        // Future placeholder for disease protection recommendations
        _buildPlaceholderCard(
          title: 'රෝග ආරක්ෂණ නිර්දේශ',
          icon: Icons.healing,
          color: Colors.orange.shade700,
          message: 'ඉදිරියේදී රෝග ආරක්ෂණ නිර්දේශ ලබා ගත හැකි වනු ඇත',
        ),
      ],
    ),
  );
}


  Widget _buildPlaceholderCard({
    required String title,
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 56, 142, 60),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          bed.name,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Color.fromARGB(255, 0, 0, 0))],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeaderImage(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(0, 226, 220, 220), Color.fromARGB(137, 226, 220, 220)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditBedScreen(bed: bed)),
          ).then((_) => _refreshBedData()),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    return Image.network(
      bed.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.green.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.white)),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.green.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo(bed.status);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(statusInfo.icon, color: statusInfo.color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bed.nextAction,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusInfo.color),
                ),
                const SizedBox(height: 4),
                Text(_getStatusDescription(), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final detailItems = [
      {'icon': Icons.spa, 'label': 'බුලත් වර්ගය', 'value': bed.betelType},
      {'icon': Icons.calendar_today, 'label': 'වගා කළ දිනය', 'value': _formatDate(bed.plantedDate)},
      {'icon': Icons.timer, 'label': 'වයස', 'value': '${bed.ageInDays} දින'},
      {'icon': Icons.straighten, 'label': 'ප්‍රමාණය', 'value': '${bed.areaSize} m²'},
      {'icon': Icons.grass, 'label': 'පැළ ගණන', 'value': bed.plantCount.toString()},
      {'icon': Icons.location_city, 'label': 'ප්‍රදේශය', 'value': bed.district},
      {'icon': Icons.home, 'label': 'ලිපිනය', 'value': bed.address},
      {'icon': Icons.grid_view, 'label': 'සමාන පඳුරු ගණන', 'value': bed.sameBedCount.toString()},
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('විස්තර', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...detailItems.map((item) => _buildDetailItem(
            item['icon'] as IconData, 
            item['label'] as String, 
            item['value'] as String,
          )),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'පොහොර යෙදීම',
              icon: Icons.water_drop,
              color: Colors.blue,
              onTap: _showAddFertilizeDialog,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'අස්වනු නෙලීම',
              icon: Icons.shopping_basket,
              color: Colors.green.shade700,
              onTap: _showAddHarvestDialog,
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
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
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
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'තවම වාර්තා කර නැත',
                style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFertilizeHistoryList() {
    final sortedHistory = List<FertilizeRecord>.from(bed.fertilizeHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    
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
          subtitle: Text('${_formatDate(record.date)} • ${record.quantity}kg'),
          trailing: record.notes.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showNotesDialog(record.notes),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHarvestHistoryList() {
    final sortedHistory = List<HarvestRecord>.from(bed.harvestHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    
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
          subtitle: Text('${_formatDate(harvest.date)} • රු.${harvest.revenueEarned.toStringAsFixed(2)}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              harvest.quality,
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void _showNotesDialog(String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('සටහන'),
        content: Text(notes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('හරි'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshBedData() async {
    try {
      setState(() => _isLoading = true);
      
      final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
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
      setState(() => _isLoading = false);
      _showErrorSnackBar('දත්ත යාවත්කාලීන කිරීමේ දෝෂයකි: ${e.toString()}');
    }
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
            _buildMenuOption(
              icon: Icons.edit,
              title: 'සංස්කරණය කරන්න',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditBedScreen(bed: bed)),
                ).then((_) => _refreshBedData());
              },
            ),
            _buildMenuOption(
              icon: Icons.update,
              title: 'තත්ත්වය යාවත්කාලීන කරන්න',
              onTap: () {
                Navigator.pop(context);
                _showStatusUpdateDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.delete,
              title: 'මකන්න',
              color: Colors.red.shade700,
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

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      onTap: onTap,
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
              child: Text('ක්‍රියාමාර්ග', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildMenuOption(
              icon: Icons.water_drop,
              title: 'පොහොර යෙදීමක් එක් කරන්න',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showAddFertilizeDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.shopping_basket,
              title: 'අස්වැන්නක් එක් කරන්න',
              color: Colors.green.shade700,
              onTap: () {
                Navigator.pop(context);
                _showAddHarvestDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.update,
              title: 'තත්ත්වය යාවත්කාලීන කරන්න',
              color: Colors.teal,
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

  void _showStatusUpdateDialog() {
    final statusOptions = [
      {'status': BetelBedStatus.healthy, 'title': 'හොඳ තත්ත්වයේ පවතී', 'icon': Icons.check_circle, 'color': Colors.green},
      {'status': BetelBedStatus.needsWatering, 'title': 'ජලය යෙදීම අවශ්‍යයි', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'status': BetelBedStatus.needsFertilizing, 'title': 'පොහොර යෙදීම අවශ්‍යයි', 'icon': Icons.grass, 'color': Colors.orange},
      {'status': BetelBedStatus.readyToHarvest, 'title': 'අස්වනු නෙලීමට සූදානම්', 'icon': Icons.shopping_basket, 'color': Colors.green.shade700},
      {'status': BetelBedStatus.diseased, 'title': 'රෝගී තත්වයේ පවතී', 'icon': Icons.sick, 'color': Colors.red},
    ];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${bed.name} - තත්ත්වය යාවත්කාලීන කරන්න'),
        children: statusOptions.map((option) => _buildStatusOption(
          status: option['status'] as BetelBedStatus,
          title: option['title'] as String,
          icon: option['icon'] as IconData,
          color: option['color'] as Color,
        )).toList(),
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
          setState(() => _isLoading = true);
          
          await _betelBedService.updateBedStatus(bed.id, status);
          await _refreshBedData();
          
          _showSuccessSnackBar('තත්ත්වය සාර්ථකව යාවත්කාලීන කරන ලදී');
        } catch (e) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('දෝෂයකි: ${e.toString()}');
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

  void _showAddFertilizeDialog() {
    final dateController = TextEditingController(text: _getTodayFormatted());
    final typeController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    
    _showFormDialog(
      title: 'නව පොහොර යෙදීමක් එක් කරන්න',
      fields: [
        _buildDateField(dateController),
        TextField(controller: typeController, decoration: const InputDecoration(labelText: 'පොහොර වර්ගය')),
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
          if (typeController.text.isEmpty || quantityController.text.isEmpty) {
            _showErrorSnackBar('කරුණාකර අවශ්‍ය තොරතුරු පුරවන්න');
            return;
          }
          
          final quantity = double.tryParse(quantityController.text);
          if (quantity == null) {
            _showErrorSnackBar('වලංගු ප්‍රමාණයක් ඇතුළත් කරන්න');
            return;
          }
          
          final date = DateTime.parse(dateController.text);
          final record = FertilizeRecord(
            date: date,
            fertilizerType: typeController.text,
            quantity: quantity,
            notes: notesController.text,
          );
          
          Navigator.pop(context);
          setState(() => _isLoading = true);
          
          await _betelBedService.addFertilizeRecord(bed.id, record);
          _showSuccessSnackBar('පොහොර යෙදීම සාර්ථකව එකතු කරන ලදී');
          
          await _refreshBedData();
        } catch (e) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('දෝෂයකි: ${e.toString()}');
        }
      },
    );
  }

  void _showAddHarvestDialog() {
    final dateController = TextEditingController(text: _getTodayFormatted());
    final leavesController = TextEditingController();
    final weightController = TextEditingController();
    final revenueController = TextEditingController();
    final qualityController = TextEditingController(text: 'A');
    final notesController = TextEditingController();
    
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
          items: ['A', 'B', 'C', 'D'].map((quality) => DropdownMenuItem<String>(
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
          
          Navigator.pop(context);
          setState(() => _isLoading = true);
          
          await _betelBedService.addHarvestRecord(bed.id, record);
          _showSuccessSnackBar('අස්වැන්න සාර්ථකව එකතු කරන ලදී');
          
          await _refreshBedData();
        } catch (e) {
          setState(() => _isLoading = false);
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
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: fields),
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

void _showDeleteConfirmation() {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('පඳුර මකන්නද?'),
      content: const Text('මෙම බුලත් පඳුර සහ එයට අදාළ සියලුම දත්ත මකා දැමෙනු ඇත. මෙය ආපසු හැරවිය නොහැක.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('අවලංගු කරන්න'),
        ),
        TextButton(
          onPressed: () async {
            try {
              // First close the dialog
              Navigator.pop(dialogContext);
              
              // Then show loading indicator
              setState(() => _isLoading = true);
              
              // Get the provider and delete the bed
              final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
              await betelBedProvider.deleteBed(bed.id);
              
              // Show success message and pop with successful deletion result
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('බුලත් පඳුර සාර්ථකව මකා දමන ලදී'))
              );
              
              // Important: Pop the current screen AFTER deletion is complete
              // and pass true to indicate a refresh is needed
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('දෝෂයකි: ${e.toString()}'))
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text('මකන්න'),
        ),
      ],
    ),
  );
}

// Helper methods
String _formatDate(DateTime date) => 
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _getTodayFormatted() => _formatDate(DateTime.now());

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

StatusInfo _getStatusInfo(BetelBedStatus status) {
  switch (status) {
    case BetelBedStatus.needsFertilizing:
      return StatusInfo(Colors.orange, Icons.water_drop);
    case BetelBedStatus.readyToHarvest:
      return StatusInfo(Colors.green.shade700, Icons.shopping_basket);
    case BetelBedStatus.needsWatering:
      return StatusInfo(Colors.blue, Icons.water);
    case BetelBedStatus.diseased:
      return StatusInfo(Colors.red, Icons.healing);
    default:
      return StatusInfo(Colors.teal, Icons.check_circle);
  }
}
}

class StatusInfo {
  final Color color;
  final IconData icon;
  
  StatusInfo(this.color, this.icon);
}