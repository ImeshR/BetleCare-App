import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeafQuantityConversionPage extends StatefulWidget {
  const LeafQuantityConversionPage({Key? key}) : super(key: key);

  @override
  _LeafQuantityConversionPageState createState() =>
      _LeafQuantityConversionPageState();
}

class _LeafQuantityConversionPageState
    extends State<LeafQuantityConversionPage> {
  final _formKey = GlobalKey<FormState>();

  // Conversion types
  final List<String> _conversionTypes = [
    'ගණන සිට බර දක්වා', // Count to Weight
    'බර සිට ගණන දක්වා', // Weight to Count
    'ප්‍රදේශය අනුව ඇස්තමේන්තුව', // Estimate by Area
  ];

  String _selectedConversionType = 'ගණන සිට බර දක්වා';

  // Leaf types
  final List<String> _leafTypes = [
    'පීදුනු කොළ (P)', // Mature Leaf
    'කෙටි කොළ (KT)', // Short Leaf
    'රෑන් කෙටි කොළ (RKT)', // Young Short Leaf
  ];

  String _selectedLeafType = 'පීදුනු කොළ (P)';

  // Input values
  double _inputValue = 0;
  double _resultValue = 0;

  // Conversion history
  List<Map<String, dynamic>> _conversionHistory = [];

  // Conversion factors (these would ideally come from a database)
  final Map<String, Map<String, double>> _conversionFactors = {
    'පීදුනු කොළ (P)': {
      'countToWeight': 0.05, // 1 leaf = 0.05 kg
      'weightToCount': 20, // 1 kg = 20 leaves
      'areaToCount': 500, // 1 square meter = 500 leaves
    },
    'කෙටි කොළ (KT)': {
      'countToWeight': 0.03, // 1 leaf = 0.03 kg
      'weightToCount': 33.33, // 1 kg = 33.33 leaves
      'areaToCount': 700, // 1 square meter = 700 leaves
    },
    'රෑන් කෙටි කොළ (RKT)': {
      'countToWeight': 0.02, // 1 leaf = 0.02 kg
      'weightToCount': 50, // 1 kg = 50 leaves
      'areaToCount': 900, // 1 square meter = 900 leaves
    },
  };

  // Input labels based on conversion type
  Map<String, Map<String, String>> _inputLabels = {
    'ගණන සිට බර දක්වා': {
      'input': 'කොළ ගණන',
      'result': 'බර (කිලෝග්‍රෑම්)',
      'inputHint': 'කොළ ගණන ඇතුළත් කරන්න',
    },
    'බර සිට ගණන දක්වා': {
      'input': 'බර (කිලෝග්‍රෑම්)',
      'result': 'කොළ ගණන',
      'inputHint': 'බර ඇතුළත් කරන්න',
    },
    'ප්‍රදේශය අනුව ඇස්තමේන්තුව': {
      'input': 'ප්‍රදේශය (වර්ග මීටර)',
      'result': 'ඇස්තමේන්තුගත කොළ ගණන',
      'inputHint': 'ප්‍රදේශය ඇතුළත් කරන්න',
    },
  };

  @override
  void initState() {
    super.initState();
    // Load any saved conversion history or preferences here
  }

  void _performConversion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      double result = 0;

      // Get the appropriate conversion factor
      final factors = _conversionFactors[_selectedLeafType];

      if (factors != null) {
        if (_selectedConversionType == 'ගණන සිට බර දක්වා') {
          result = _inputValue * factors['countToWeight']!;
        } else if (_selectedConversionType == 'බර සිට ගණන දක්වා') {
          result = _inputValue * factors['weightToCount']!;
        } else if (_selectedConversionType == 'ප්‍රදේශය අනුව ඇස්තමේන්තුව') {
          result = _inputValue * factors['areaToCount']!;
        }
      }

      // Save to history
      _conversionHistory.add({
        'date': DateTime.now(),
        'conversionType': _selectedConversionType,
        'leafType': _selectedLeafType,
        'inputValue': _inputValue,
        'resultValue': result,
      });

      setState(() {
        _resultValue = result;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('පරිවර්තනය සාර්ථකයි')),
      );
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('කොළ ප්‍රමාණ පරිවර්තනය'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConversionCard(),
            SizedBox(height: 16),
            _buildResultCard(),
            SizedBox(height: 16),
            _buildConversionHistoryCard(),
            SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard() {
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
                  Icon(Icons.swap_horiz, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "පරිවර්තන විස්තර",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'පරිවර්තන වර්ගය',
                  border: OutlineInputBorder(),
                ),
                value: _selectedConversionType,
                items: _conversionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedConversionType = value!;
                    _resultValue =
                        0; // Reset result when changing conversion type
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'කොළ වර්ගය',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLeafType,
                items: _leafTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLeafType = value!;
                    _resultValue = 0; // Reset result when changing leaf type
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: _inputLabels[_selectedConversionType]!['input'],
                  hintText: _inputLabels[_selectedConversionType]!['inputHint'],
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'අගයක් ඇතුළත් කරන්න';
                  }
                  if (double.tryParse(value) == null) {
                    return 'වලංගු සංඛ්‍යාවක් ඇතුළත් කරන්න';
                  }
                  return null;
                },
                onSaved: (value) {
                  _inputValue = double.parse(value!);
                },
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _performConversion,
                  icon: Icon(Icons.calculate),
                  label: Text('පරිවර්තනය කරන්න'),
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
                  "පරිවර්තන ප්‍රතිඵලය",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _inputLabels[_selectedConversionType]!['result'] ??
                        'ප්‍රතිඵලය',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _resultValue > 0 ? _formatNumber(_resultValue) : '0',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionHistoryCard() {
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
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "පරිවර්තන ඉතිහාසය",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_conversionHistory.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _conversionHistory.clear();
                      });
                    },
                    icon: Icon(Icons.delete, size: 18),
                    label: Text("මකන්න"),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (_conversionHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "පරිවර්තන ඉතිහාසය නොමැත",
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
                itemCount: _conversionHistory.length > 5
                    ? 5
                    : _conversionHistory.length,
                itemBuilder: (context, index) {
                  final reversedIndex = _conversionHistory.length - 1 - index;
                  final item = _conversionHistory[reversedIndex];
                  return ListTile(
                    title: Text(
                      "${item['leafType']} - ${item['conversionType']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${_formatNumber(item['inputValue'])} → ${_formatNumber(item['resultValue'])}",
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

  Widget _buildInfoCard() {
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
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "පරිවර්තන තොරතුරු",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoItem(
              title: "පීදුනු කොළ (P)",
              details: "1 කොළයක් = 0.05 kg | 1 kg = 20 කොළ",
            ),
            _buildInfoItem(
              title: "කෙටි කොළ (KT)",
              details: "1 කොළයක් = 0.03 kg | 1 kg = 33 කොළ",
            ),
            _buildInfoItem(
              title: "රෑන් කෙටි කොළ (RKT)",
              details: "1 කොළයක් = 0.02 kg | 1 kg = 50 කොළ",
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Text(
              "සටහන: මෙම පරිවර්තන සාධක සාමාන්‍ය අගයන් වන අතර, කොළ ප්‍රමාණය, වර්ගය සහ තත්ත්වය අනුව වෙනස් විය හැක.",
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
