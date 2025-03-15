import 'package:betlecare/pages/harvest/predict/yiled_main_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:betlecare/services/index.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  double? _landSize;
  String? _soilType;
  bool _isLoading = false;
  String _loadingMessage = '';

  final TextEditingController _landSizeController = TextEditingController();

  // Replace hardcoded lands with fetched data from Supabase
  List<Map<String, dynamic>> _lands = [];
  late SupabaseService _supabaseService;

  // Add these variables to the _AddPredictionPageState class
  Map<String, dynamic>? _predictionResults;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _initializeSupabaseService();
  }

  Future<void> _initializeSupabaseService() async {
    _supabaseService = await SupabaseService.init();
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await _supabaseService.read('land_size',
          column: 'user_id', value: userId);

      setState(() {
        _lands = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching lands: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _landSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isLastHarvest) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastHarvest
          ? _lastHarvestDate ?? DateTime.now()
          : _lastHarvestDate!.add(Duration(days: 7)),
      firstDate: isLastHarvest ? DateTime(2000) : _lastHarvestDate!,
      lastDate: isLastHarvest
          ? DateTime.now()
          : _lastHarvestDate!.add(
              Duration(days: 365)), // Allow up to a year for expected harvest
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
    if (_selectedLand == null ||
        _lastHarvestDate == null ||
        _expectedHarvestDate == null) {
      throw Exception('ස්ථානය සහ දින තෝරා ගත යුතුය');
    }

    // Find the selected land from the fetched lands
    final selectedLandData =
        _lands.firstWhere((land) => land['name'] == _selectedLand);

    // Note: You'll need to ensure your land_size table has latitude and longitude columns
    // If not, you might need to modify this part or add a default location
    final latitude = selectedLandData['latitude'] as double? ?? 7.8731;
    final longitude = selectedLandData['longitude'] as double? ?? 80.7718;

    try {
      var weatherData = await WeatherService.fetchWeatherData(
        latitude,
        longitude,
        _lastHarvestDate!,
        _expectedHarvestDate!,
      );
      print('Weather Data: $weatherData');
      return weatherData;
    } catch (e) {
      print('Error fetching weather data: $e');
      return {
        'rainfall': 0,
        'min_temp': 0,
        'max_temp': 0,
      };
    }
  }

  String _analyzeSoilType() {
    if (_selectedLand == null) {
      return 'Unknown Soil Type';
    }
    final selectedLandData =
        _lands.firstWhere((land) => land['name'] == _selectedLand);

    print('Selected Land Data: $selectedLandData');

    return SoilService.analyzeSoilType(
        selectedLandData['location'] as String? ?? 'Unknown');
  }

  //save prediction to database
  Future<void> _savePredictionToDatabase() async {
    if (_predictionResults == null || _selectedLand == null) {
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Find the selected land data
      final selectedLandData =
          _lands.firstWhere((land) => land['name'] == _selectedLand);

      // Format dates for API
      final lastHarvestFormatted =
          DateFormat('MM/dd/yyyy').format(_lastHarvestDate!);
      final expectedHarvestFormatted =
          DateFormat('MM/dd/yyyy').format(_expectedHarvestDate!);

      _soilType = _analyzeSoilType();

      // Create the harvest history record
      final harvestHistoryData = {
        'user_id': userId,
        'land_name': selectedLandData['name'],
        'land_location': selectedLandData['location'],
        'land_size': selectedLandData['area'],
        'last_harvest_date': lastHarvestFormatted,
        'expected_harvest_date': expectedHarvestFormatted,
        'planted_sticks': _plantedSticks,
        'soil_type': _soilType,
        'predicted_p': _predictionResults!['P'],
        'predicted_kt': _predictionResults!['KT'],
        'predicted_rkt': _predictionResults!['RKT'],
        'total_predicted': _predictionResults!['P'] +
            _predictionResults!['KT'] +
            _predictionResults!['RKT'],
        'created_at': DateTime.now().toIso8601String(),
      };

      print('Harvest History Data: $harvestHistoryData');

      // Save to Supabase
      final response = await _supabaseService.create(
          'harvest_predict_history', harvestHistoryData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('පුරෝකථනය සාර්ථකව සුරකින ලදී')),
      );

      print('Saved prediction to database: $response');
    } catch (e) {
      print('Error saving prediction to database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('පුරෝකථනය සුරැකීමේ දෝෂයක්: $e')),
      );
    }
  }

  // Updated _submitForm method to save prediction to database
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
        _showResults = false;
        _loadingMessage = 'පස වර්ගය විශ්ලේෂණය කරමින්...';
      });
      _soilType = _analyzeSoilType();
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _loadingMessage = 'දින කාලය ගණනය කරමින්...';
      });
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _loadingMessage = 'කාලගුණ දත්ත රැස් කරමින්...';
      });
      final weatherData = await _fetchWeatherData();

      setState(() {
        _loadingMessage = 'අස්වැන්න පුරෝකථනය කරමින්...';
      });

      final selectedLandData =
          _lands.firstWhere((land) => land['name'] == _selectedLand);

      // Calculate days since last harvest
      final daysSinceLastHarvest =
          _expectedHarvestDate!.difference(_lastHarvestDate!).inDays;

      // Format dates for API
      final lastHarvestFormatted =
          DateFormat('MM/dd/yyyy').format(_lastHarvestDate!);
      final expectedHarvestFormatted =
          DateFormat('MM/dd/yyyy').format(_expectedHarvestDate!);

      // Prepare request body for prediction API
      final requestBody = {
        "Last Harvest Date": [lastHarvestFormatted],
        "Expected Harvest Date": [expectedHarvestFormatted],
        "Days Since Last Harvest": [daysSinceLastHarvest],
        "Location": [selectedLandData['location'] ?? "Unknown"],
        "Soil Type": [_soilType ?? "Unknown Soil Type"],
        "Rainfall Seq (mm)": [
          weatherData['rainfall'] ??
              [
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0,
                0.0
              ]
        ],
        "Min Temp Seq (°C)": [
          weatherData['min_temp'] ??
              [
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0,
                25.0
              ]
        ],
        "Max Temp Seq (°C)": [
          weatherData['max_temp'] ??
              [
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0,
                35.0
              ]
        ],
        "Land Size (acres)": [
          double.tryParse(_landSize?.toString() ?? "0.0") ?? 0.0
        ],
        "Planted Sticks": [_plantedSticks ?? 0]
      };

      print('Request Body: $requestBody');

      try {
        // Get the API URL from environment variables
        final apiUrl = dotenv.env['HARVEST_PREDICT']?.trim();
        if (apiUrl == null || apiUrl.isEmpty) {
          throw Exception('API URL is missing');
        }

        // Make the API call
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          setState(() {
            _predictionResults = responseData;
            _showResults = true;
          });

          print('Prediction Results: $_predictionResults');

          // Save prediction to database
          await _savePredictionToDatabase();
        } else {
          print('API Error: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'පුරෝකථන සේවාව සම්බන්ධ වීමේ දෝෂයක්: ${response.statusCode}')),
          );
        }
      } catch (e) {
        print('Error calling prediction API: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('පුරෝකථන සේවාව සම්බන්ධ වීමේ දෝෂයක්: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to build the results UI
  Widget _buildResultsCard() {
    if (!_showResults || _predictionResults == null) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'අස්වැන්න පුරෝකථනය',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            SizedBox(height: 8),
            _buildResultRow('පීදුනු කොළ (P)', _predictionResults!['P']),
            _buildResultRow('කෙටි කොළ (KT)', _predictionResults!['KT']),
            _buildResultRow('රෑන් කෙටි කොළ (RKT)', _predictionResults!['RKT']),
            SizedBox(height: 8),
            Text(
              'මුළු අස්වැන්න: ${(_predictionResults!['P'] + _predictionResults!['KT'] + _predictionResults!['RKT']).toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build each result row
  Widget _buildResultRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _isLoading && _lands.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          decoration:
                              const InputDecoration(labelText: 'මැනපු ඉඩම්'),
                          value: _selectedLand,
                          items: _lands.map((land) {
                            return DropdownMenuItem<String>(
                              value: land['name'] as String,
                              child: Text(
                                  '${land['name']} (${land['area'].toStringAsFixed(2)} අක්කර)'),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLand = newValue;
                              if (newValue != null) {
                                var selectedLand = _lands.firstWhere(
                                    (land) => land['name'] == newValue);
                                _landSizeController.text = double.tryParse(
                                            selectedLand['area'].toString())
                                        ?.toStringAsFixed(2) ??
                                    '0.00';
                                _landSize = selectedLand['area'];
                              }
                            });
                          },
                          validator: (value) =>
                              value == null ? 'කරුණාකර ඉඩමක් තෝරන්න' : null,
                        ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to the land measurement page
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => YieldMainPage()));
                      },
                      child: const Text('අලුත් ඉඩමක් මනින්න'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'රෝපණය කළ ඉණි ගණන'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'කරුණාකර රෝපණය කළ ඉණි ගණන ඇතුළත් කරන්න';
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
                  const SizedBox(height: 24),
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
                        : DateFormat('yyyy/MM/dd')
                            .format(_expectedHarvestDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _lastHarvestDate == null
                        ? null
                        : () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _landSizeController,
                    enabled: false,
                    decoration: const InputDecoration(
                        labelText: 'ඉඩම් ප්‍රමාණය (අක්කර)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'කරුණාකර ඉඩම් ප්‍රමාණය ඇතුළත් කරන්න';
                      }
                      if (double.tryParse(value) == null) {
                        return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _landSize = double.parse(value!);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildResultsCard(),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: const Text('ඉදිරිපත් කරන්න'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to the harvest history page
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => HarvestHistoryPage()));
                      },
                      child: const Text('පෙර පුරෝකථන බලන්න'),
                    ),
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
