import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeafHarvestingCalculatorPage extends StatefulWidget {
  const LeafHarvestingCalculatorPage({Key? key}) : super(key: key);

  @override
  _LeafHarvestingCalculatorPageState createState() =>
      _LeafHarvestingCalculatorPageState();
}

class _LeafHarvestingCalculatorPageState
    extends State<LeafHarvestingCalculatorPage> {
  final _formKey = GlobalKey<FormState>();

  // Leaf types and their quantities
  final Map<String, int> _leafQuantities = {
    'පීදුනු කොළ (P)': 0, // Mature Leaf
    'කෙටි කොළ (KT)': 0, // Short Leaf
    'රෑන් කෙටි කොළ (RKT)': 0, // Young Short Leaf
  };

  // Land size options in අක්කර (acres)
  final List<Map<String, dynamic>> _landSizeOptions = [
    {'label': 'බාගයක්', 'value': 0.5},
    {'label': 'එකක්', 'value': 1.0},
    {'label': 'එක හමාරක්', 'value': 1.5},
    {'label': 'දෙකක්', 'value': 2.0},
  ];

  double _selectedLandSize = 1.0;
  String _selectedLandSizeLabel = 'එකක්';

  // Results
  int _totalLeaves = 0;
  int _totalBulatAtCount = 0;
  int _requiredLabourers = 0;
  String _harvestingSchedule = '';
  Map<String, int> _bulatAtByType = {};

  // Calculation history
  List<Map<String, dynamic>> _calculationHistory = [];

  // Conversion factors
  final Map<String, Map<String, dynamic>> _conversionFactors = {
    'පීදුනු කොළ (P)': {
      'leavesPerAcre': 10000,
      'packsPerBulatAta': 20,
      'labourersPerAcre': 6,
    },
    'කෙටි කොළ (KT)': {
      'leavesPerAcre': 12000,
      'packsPerBulatAta': 20,
      'labourersPerAcre': 5,
    },
    'රෑන් කෙටි කොළ (RKT)': {
      'leavesPerAcre': 15000,
      'packsPerBulatAta': 20,
      'labourersPerAcre': 4,
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialize bulatAtByType with zeros
    _leafQuantities.keys.forEach((type) {
      _bulatAtByType[type] = 0;
    });
  }

  void _performCalculation() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      int totalLeaves = 0;
      int totalBulatAt = 0;
      int requiredLabourers = 0;
      Map<String, int> bulatAtByType = {};

      // Calculate for each leaf type
      _leafQuantities.forEach((leafType, quantity) {
        final factors = _conversionFactors[leafType];

        if (factors != null && quantity > 0) {
          totalLeaves += quantity;

          // Calculate බුලත් අත් for this type
          int bulatAt = (quantity / factors['packsPerBulatAta']).round();
          bulatAtByType[leafType] = bulatAt;
          totalBulatAt += bulatAt;

          // Add to required laborers based on leaf type and quantity
          double acreEquivalent = quantity / factors['leavesPerAcre'];
          requiredLabourers +=
              (acreEquivalent * factors['labourersPerAcre']).round();
        } else {
          bulatAtByType[leafType] = 0;
        }
      });

      // Generate harvesting schedule based on total leaves
      String schedule = '';
      if (_selectedLandSize <= 1.0) {
        schedule =
            'දින 2ක් අවශ්‍ය වේ. උදේ 6:00 සිට 10:30 දක්වා සහ සවස 3:00 සිට 6:00 දක්වා නෙලීම සිදු කරන්න.';
      } else {
        int days = (_selectedLandSize > 1.5) ? 4 : 3;
        schedule =
            'දින $days අවශ්‍ය වේ. උදේ 6:00 සිට 10:30 දක්වා සහ සවස 3:00 සිට 6:00 දක්වා නෙලීම සිදු කරන්න.';
      }

      // Save to history
      _calculationHistory.add({
        'date': DateTime.now(),
        'landSize': _selectedLandSize,
        'landSizeLabel': _selectedLandSizeLabel,
        'leafQuantities': Map<String, int>.from(_leafQuantities),
        'totalLeaves': totalLeaves,
        'totalBulatAt': totalBulatAt,
        'requiredLabourers': requiredLabourers,
      });

      setState(() {
        _totalLeaves = totalLeaves;
        _totalBulatAtCount = totalBulatAt;
        _requiredLabourers = requiredLabourers;
        _harvestingSchedule = schedule;
        _bulatAtByType = bulatAtByType;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ගණනය කිරීම සාර්ථකයි')),
      );
    }
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('කොළ අස්වනු ගණනය කිරීම'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            SizedBox(height: 16),
            _buildResultCard(),
            SizedBox(height: 16),
            _buildHarvestingInfoCard(),
            SizedBox(height: 16),
            _buildCalculationHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "කොළ ප්‍රමාණය ඇතුලත් කරන්න",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Land size selection
              DropdownButtonFormField<double>(
                decoration: InputDecoration(
                  labelText: 'ඉඩම් ප්‍රමාණය (අක්කර)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLandSize,
                items: _landSizeOptions.map((option) {
                  return DropdownMenuItem<double>(
                    value: option['value'],
                    child: Text('අක්කර ${option['label']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLandSize = value!;
                    _selectedLandSizeLabel = _landSizeOptions.firstWhere(
                        (option) => option['value'] == value)['label'];
                  });
                },
              ),
              SizedBox(height: 16),

              // Input fields for each leaf type
              ..._leafQuantities.keys.map((leafType) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '$leafType කොළ ගණන',
                      hintText: '$leafType කොළ ගණන ඇතුළත් කරන්න',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.spa, color: Colors.green),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _leafQuantities[leafType]! > 0
                        ? _leafQuantities[leafType].toString()
                        : '',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'වලංගු සංඛ්‍යාවක් ඇතුළත් කරන්න';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        _leafQuantities[leafType] = int.parse(value);
                      } else {
                        _leafQuantities[leafType] = 0;
                      }
                    },
                  ),
                );
              }).toList(),

              SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _performCalculation,
                  icon: Icon(Icons.calculate),
                  label: Text('ගණනය කරන්න'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "ගණනය කිරීමේ ප්‍රතිඵල",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Total leaves
            _buildResultItem(
              icon: Icons.spa,
              title: "මුළු කොළ ගණන",
              value: _totalLeaves > 0 ? _formatNumber(_totalLeaves) : '0',
            ),

            // Total බුලත් අත්
            _buildResultItem(
              icon: Icons.inventory_2,
              title: "මුළු බුලත් අත් ගණන",
              value: _totalBulatAtCount > 0
                  ? _formatNumber(_totalBulatAtCount)
                  : '0',
              subtitle: "(බුලත් අතක් = කොළ 20)",
            ),

            // බුලත් අත් by leaf type
            if (_totalBulatAtCount > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "කොළ වර්ග අනුව බුලත් අත් ගණන:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._bulatAtByType.entries.where((e) => e.value > 0).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key),
                      ),
                      Text(
                        "${_formatNumber(entry.value)} බුලත් අත්",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],

            // Required laborers
            _buildResultItem(
              icon: Icons.people,
              title: "අවශ්‍ය කම්කරුවන් ගණන",
              value:
                  _requiredLabourers > 0 ? _requiredLabourers.toString() : '0',
            ),

            // Harvesting schedule
            if (_harvestingSchedule.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
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
                          Icon(Icons.schedule,
                              color: Colors.amber.shade800, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "නෙලීමේ කාලසටහන",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(_harvestingSchedule),
                      SizedBox(height: 4),
                      Text(
                        "සටහන: කොළ මැලවීම (හෙයන්ව) වැළැක්වීමට උදේ 10:30 සිට සවස 3:00 දක්වා නෙලීම නවතා දමන්න.",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "නෙලීමේ උපදෙස්",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoItem(
              title: "කොළ මැලවීම (හෙයන්ව) වැළැක්වීම",
              details:
                  "උදේ 6:00 සිට 10:30 දක්වා සහ සවස 3:00 සිට 6:00 දක්වා පමණක් නෙලීම සිදු කරන්න.",
            ),
            _buildInfoItem(
              title: "අක්කර එකක් සඳහා කම්කරුවන්",
              details:
                  "අක්කර එකක් සඳහා කම්කරුවන් 6 දෙනෙකු අවශ්‍ය වේ. දින දෙකක් තුළ නෙලීම අවසන් කළ හැකිය.",
            ),
            _buildInfoItem(
              title: "බුලත් අත් ගණනය",
              details: "කොළ 20ක් = බුලත් අතක් 1",
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Text(
              "සටහන: මෙම ගණනය කිරීම් සාමාන්‍ය අගයන් වන අතර, කොළ ප්‍රමාණය, වර්ගය සහ තත්ත්වය අනුව වෙනස් විය හැක.",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      "ගණනය කිරීමේ \nඉතිහාසය",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_calculationHistory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _calculationHistory.clear();
                      });
                    },
                    icon: Icon(Icons.delete, size: 18),
                    label: Text("මකන්න"),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (_calculationHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "ගණනය කිරීමේ ඉතිහාසය නොමැත",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _calculationHistory.length > 5
                    ? 5
                    : _calculationHistory.length,
                itemBuilder: (context, index) {
                  final reversedIndex = _calculationHistory.length - 1 - index;
                  final item = _calculationHistory[reversedIndex];

                  // Calculate total leaves for this history item
                  int totalLeaves = item['totalLeaves'];

                  return ListTile(
                    title: Text(
                      "අක්කර ${item['landSizeLabel']} - කොළ ${_formatNumber(totalLeaves)}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "බුලත් අත්: ${_formatNumber(item['totalBulatAt'])} | කම්කරුවන්: ${item['requiredLabourers']}",
                    ),
                    trailing: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(item['date']),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String title, required String details}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Colors.green),
          SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  details,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
