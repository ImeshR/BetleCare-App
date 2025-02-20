import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../widgets/appbar/app_bar.dart';

class AddPredictionPage extends StatefulWidget {
  const AddPredictionPage({Key? key}) : super(key: key);

  @override
  _AddPredictionPageState createState() => _AddPredictionPageState();
}

class _AddPredictionPageState extends State<AddPredictionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLand;
  int? _plantedSticks;
  DateTime? _lastHarvestDate;
  DateTime? _expectedHarvestDate;
  bool _isLoading = false;
  String _loadingMessage = '';

  // This should be fetched from your database
  List<Map<String, dynamic>> _measuredLands = [
    {'name': 'පුත්තලම ඉඩම', 'location': 'පුත්තලම', 'size': 0.5},
    {'name': 'ආණමඩුව කුඹුර', 'location': 'ආණමඩුව', 'size': 1.0},
    {'name': 'කුරුණෑගල වත්ත', 'location': 'කුරුණෑගල', 'size': 0.75},
  ];

  Future<void> _selectDate(BuildContext context, bool isLastHarvest) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastHarvest ? _lastHarvestDate ?? DateTime.now() : _lastHarvestDate!.add(Duration(days: 7)),
      firstDate: isLastHarvest ? DateTime(2000) : _lastHarvestDate!,
      lastDate: isLastHarvest ? DateTime.now() : _lastHarvestDate!.add(Duration(days: 7)),
    );
    if (picked != null) {
      setState(() {
        if (isLastHarvest) {
          _lastHarvestDate = picked;
          _expectedHarvestDate = null; // Reset expected harvest date
        } else {
          _expectedHarvestDate = picked;
        }
      });
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherData() async {
    if (_selectedLand == null || _lastHarvestDate == null || _expectedHarvestDate == null) {
      throw Exception('ස්ථානය සහ දින තෝරා ගත යුතුය');
    }

    // Simulating API call to your weather data service
    await Future.delayed(Duration(seconds: 2));

    // This is a mock response. Replace this with actual API call to your weather service
    return {
      'rainfall': [0.0, 0.0, 0.0, 10.3, 11.0, 15.2, 0.0],
      'min_temp': [24.0, 24.3, 25.0, 24.0, 24.0, 24.9, 25.8],
      'max_temp': [33.5, 34.4, 35.5, 33.5, 33.0, 34.0, 35.4],
    };
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
        _loadingMessage = 'පස වර්ගය විශ්ලේෂණය කරමින්...';
      });
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _loadingMessage = 'දින කාලය ගණනය කරමින්...';
      });
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _loadingMessage = 'කාලගුණ දත්ත රැස් කරමින්...';
      });
      final weatherData = await _fetchWeatherData();

      setState(() {
        _loadingMessage = 'අස්වැන්න පුරෝකථනය කරමින්...';
      });
      await Future.delayed(Duration(seconds: 2));

      final selectedLandData = _measuredLands.firstWhere((land) => land['name'] == _selectedLand);

      final predictionData = {
        'Land Name': _selectedLand,
        'Location': selectedLandData['location'],
        'Land Size (acres)': selectedLandData['size'],
        'Planted Sticks': _plantedSticks,
        'Last Harvest Date': DateFormat('yyyy/MM/dd').format(_lastHarvestDate!),
        'Expected Harvest Date': DateFormat('yyyy/MM/dd').format(_expectedHarvestDate!),
        'Days Until Harvest': _expectedHarvestDate!.difference(_lastHarvestDate!).inDays,
        'Rainfall Seq (mm)': weatherData['rainfall'],
        'Min Temp Seq (°C)': weatherData['min_temp'],
        'Max Temp Seq (°C)': weatherData['max_temp'],
      };

      // TODO: Send predictionData to your backend or process it as needed
      print(predictionData);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('පුරෝකථන දත්ත සාර්ථකව යවන ලදී')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppbar(
        title: 'අස්වැන්න පුරෝකථනය',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ඉඩම තෝරන්න:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'මැනපු ඉඩම්'),
                    value: _selectedLand,
                    items: _measuredLands.map((land) {
                      return DropdownMenuItem<String>(
                        value: land['name'] as String,
                        child: Text('${land['name']} (${land['size']} අක්කර)'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLand = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'කරුණාකර ඉඩමක් තෝරන්න' : null,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to the land measurement page
                        Navigator.pop(context); // This is a placeholder, replace with actual navigation
                      },
                      child: Text('අලුත් ඉඩමක් මනින්න' , style: TextStyle(color: Colors.green[700])),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'රෝපණය කළ දඬු ගණන'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'කරුණාකර රෝපණය කළ දඬු ගණන ඇතුළත් කරන්න';
                      }
                      if (int.tryParse(value) == null) {
                        return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _plantedSticks = int.parse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('අවසන් අස්වනු දිනය'),
                    subtitle: Text(_lastHarvestDate == null
                        ? 'තෝරා නැත'
                        : DateFormat('yyyy/MM/dd').format(_lastHarvestDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                  ListTile(
                    title: const Text('අපේක්ෂිත අස්වනු දිනය'),
                    subtitle: Text(_expectedHarvestDate == null
                        ? 'තෝරා නැත'
                        : DateFormat('yyyy/MM/dd').format(_expectedHarvestDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _lastHarvestDate == null
                        ? null
                        : () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: Text('ඉදිරිපත් කරන්න' , style: TextStyle(color: Colors.green[700])),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'මෙම පුරෝකථනය තෝරාගත් ස්ථානයේ සහ දත්ත කාල සීමාවේ කාලගුණ තත්වයන් මත පදනම්ව අනුමාන දත්ත වේ.',
                          style: TextStyle(color: Colors.blue , fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

