import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:betlecare/services/index.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class YieldSummaryPage extends StatefulWidget {
  final String landName;
  const YieldSummaryPage({Key? key, required this.landName}) : super(key: key);

  @override
  _YieldSummaryPageState createState() => _YieldSummaryPageState();
}

class _YieldSummaryPageState extends State<YieldSummaryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _harvestDate = DateTime.now();
  double _totalYield = 0;
  double _pYield = 0;
  double _ktYield = 0;
  double _rktYield = 0;
  bool _isLoading = false;
  String _loadingMessage = '';

  late SupabaseService _supabaseService;
  bool _isInitialized = false;

  List<Map<String, dynamic>> _harvestData = [];
  List<Map<String, dynamic>> _predictionData = [];

  // For chart display
  List<Map<String, dynamic>> _filteredPredictions = [];
  List<Map<String, dynamic>> _filteredActuals = [];
  List<String> _weekLabels = [];

  // Month filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    // Initialize date formatting
    initializeDateFormatting();
    _initializeSupabaseService();
  }

  Future<void> _initializeSupabaseService() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'දත්ත ලබා ගනිමින්...';
    });

    try {
      _supabaseService = await SupabaseService.init();
      await _fetchData();
      _prepareChartData();
      _initializeAvailableYears();
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Supabase service: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දත්ත ලබා ගැනීමේ දෝෂයක්: $e')),
      );
    }
  }

  void _initializeAvailableYears() {
    Set<int> years = {};

    // Add years from predictions
    for (var pred in _predictionData) {
      try {
        final date =
            DateTime.parse(pred['expected_harvest_date'] ?? '2000-01-01');
        years.add(date.year);
      } catch (e) {
        // Skip invalid dates
      }
    }

    // Add years from actual harvests
    for (var harvest in _harvestData) {
      try {
        final date = DateTime.parse(harvest['harvest_date'] ?? '2000-01-01');
        years.add(date.year);
      } catch (e) {
        // Skip invalid dates
      }
    }

    // If no years found, add current year
    if (years.isEmpty) {
      years.add(DateTime.now().year);
    }

    _availableYears = years.toList()..sort();

    // Set selected year to most recent
    if (_availableYears.isNotEmpty) {
      _selectedYear = _availableYears.last;
    }
  }

  void _prepareChartData() {
    // Filter data for selected month and year
    _filterDataByMonth();

    // Generate week labels based on filtered data
    _generateWeekLabels();
  }

  void _filterDataByMonth() {
    final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final endOfMonth =
        DateTime(_selectedYear, _selectedMonth + 1, 0); // Last day of month

    // Filter predictions for selected month
    _filteredPredictions = _predictionData.where((pred) {
      try {
        final date =
            DateTime.parse(pred['expected_harvest_date'] ?? '2000-01-01');
        return date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    // Filter actual harvests for selected month
    _filteredActuals = _harvestData.where((harvest) {
      try {
        final date = DateTime.parse(harvest['harvest_date'] ?? '2000-01-01');
        return date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort by date
    _filteredPredictions.sort((a, b) {
      final dateA = DateTime.parse(a['expected_harvest_date'] ?? '2000-01-01');
      final dateB = DateTime.parse(b['expected_harvest_date'] ?? '2000-01-01');
      return dateA.compareTo(dateB); // Ascending order
    });

    _filteredActuals.sort((a, b) {
      final dateA = DateTime.parse(a['harvest_date'] ?? '2000-01-01');
      final dateB = DateTime.parse(b['harvest_date'] ?? '2000-01-01');
      return dateA.compareTo(dateB); // Ascending order
    });

    print('Filtered predictions: ${_filteredPredictions.length}');
    print('Filtered actuals: ${_filteredActuals.length}');
  }

  void _generateWeekLabels() {
    _weekLabels = [];

    // Get all dates from both predictions and actuals
    List<DateTime> allDates = [];

    for (var pred in _filteredPredictions) {
      try {
        allDates
            .add(DateTime.parse(pred['expected_harvest_date'] ?? '2000-01-01'));
      } catch (e) {
        // Skip invalid dates
      }
    }

    for (var harvest in _filteredActuals) {
      try {
        allDates.add(DateTime.parse(harvest['harvest_date'] ?? '2000-01-01'));
      } catch (e) {
        // Skip invalid dates
      }
    }

    // Sort dates
    allDates.sort();

    // Use actual dates as labels
    for (var date in allDates) {
      // Format date as dd/MM
      _weekLabels.add(DateFormat('dd/MM').format(date));
    }

    // If no dates, create default labels
    if (_weekLabels.isEmpty) {
      final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
      final endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);

      // Add some sample dates
      for (var i = 1; i <= endOfMonth.day; i += 7) {
        final date = DateTime(_selectedYear, _selectedMonth, i);
        _weekLabels.add(DateFormat('dd/MM').format(date));
      }
    }

    print('Week labels: $_weekLabels');
  }

  Future<void> _fetchData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch harvest data
      final harvestResponse = await _supabaseService.read(
        'harvest_monitor_history',
        column: 'land_name',
        value: widget.landName,
      );

      // Fetch prediction data
      final predictionResponse = await _supabaseService.read(
        'harvest_predict_history',
        column: 'land_name',
        value: widget.landName,
      );

      // Sort data by date
      harvestResponse.sort((a, b) {
        final dateA = DateTime.parse(a['harvest_date'] ?? '2000-01-01');
        final dateB = DateTime.parse(b['harvest_date'] ?? '2000-01-01');
        return dateB.compareTo(dateA); // Descending order
      });

      predictionResponse.sort((a, b) {
        final dateA =
            DateTime.parse(a['expected_harvest_date'] ?? '2000-01-01');
        final dateB =
            DateTime.parse(b['expected_harvest_date'] ?? '2000-01-01');
        return dateB.compareTo(dateA); // Descending order
      });

      print('Harvest data: $harvestResponse');
      print('Prediction data: $predictionResponse');

      setState(() {
        _harvestData = harvestResponse;
        _predictionData = predictionResponse;
      });
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('දත්ත ලබා ගැනීමේ දෝෂයක්: $e')),
      );
    }
  }

  Future<void> _addHarvest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
        _loadingMessage = 'අස්වැන්න දත්ත සුරකිමින්...';
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id;

        if (userId == null) {
          throw Exception('User not logged in');
        }

        // Get land details
        final landResponse = await _supabaseService.read(
          'land_size',
          column: 'name',
          value: widget.landName,
        );

        if (landResponse.isEmpty) {
          throw Exception('Land not found');
        }

        final landData = landResponse.first;

        // Format date
        final harvestDateFormatted =
            DateFormat('yyyy-MM-dd').format(_harvestDate);

        // Create harvest record
        final harvestData = {
          'user_id': userId,
          'land_name': widget.landName,
          'land_location': landData['location'],
          'land_size': landData['area'],
          'harvest_date': harvestDateFormatted,
          'total_yield': _totalYield,
          'p_yield': _pYield,
          'kt_yield': _ktYield,
          'rkt_yield': _rktYield,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Save to Supabase
        await _supabaseService.create('harvest_monitor_history', harvestData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('අස්වැන්න දත්ත සාර්ථකව සුරකින ලදී')),
        );

        // Refresh data
        await _fetchData();
        _prepareChartData();

        // Clear form fields after successful submission
        setState(() {
          // Reset to default values
          _harvestDate = DateTime.now(); // Reset to current date
          _totalYield = 0;
          _pYield = 0;
          _ktYield = 0;
          _rktYield = 0;

          // Reset the form
          _formKey.currentState!.reset();
        });
      } catch (e) {
        print('Error adding harvest: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('අස්වැන්න දත්ත සුරැකීමේ දෝෂයක්: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Format quantity as "1K", "2K", etc.
  String formatQuantity(dynamic value) {
    if (value == null) return '0';
    double quantity = 0;

    if (value is int) {
      quantity = value.toDouble();
    } else if (value is double) {
      quantity = value;
    } else if (value is String) {
      quantity = double.tryParse(value) ?? 0;
    }

    return quantity.toStringAsFixed(0);
  }

  // Format large numbers as "5K", "10K", etc.
  String formatLargeNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _updateMonthFilter(int month) {
    setState(() {
      _selectedMonth = month;
      _prepareChartData();
    });
  }

  void _updateYearFilter(int year) {
    setState(() {
      _selectedYear = year;
      _prepareChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('අස්වැන්න පිළිබඳ සාරාංශය - ${widget.landName}'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          _isInitialized
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLastHarvestCard(),
                      SizedBox(height: 16),
                      _buildMonthFilter(),
                      SizedBox(height: 16),
                      _buildYieldChart(),
                      SizedBox(height: 16),
                      _buildAddHarvestForm(),
                    ],
                  ),
                )
              : Center(child: Text('දත්ත ලබා ගනිමින්...')),
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

  Widget _buildMonthFilter() {
    final months = [
      'ජනවාරි',
      'පෙබරවාරි',
      'මාර්තු',
      'අප්‍රේල්',
      'මැයි',
      'ජූනි',
      'ජූලි',
      'අගෝස්තු',
      'සැප්තැම්බර්',
      'ඔක්තෝබර්',
      'නොවැම්බර්',
      'දෙසැම්බර්'
    ];

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
                Icon(Icons.filter_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "මාසය තෝරන්න:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'වසර',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedYear,
                    items: _availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _updateYearFilter(value);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'මාසය',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(months[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) _updateMonthFilter(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastHarvestCard() {
    final lastHarvest = _harvestData.isNotEmpty ? _harvestData.first : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "අවසන් අස්වැන්න විස්තරය:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (lastHarvest != null) ...[
              _buildInfoRow(
                  Icons.place, "ඉඩමේ නම:", lastHarvest['land_name'], true),
              _buildInfoRow(Icons.location_on, "ස්ථානය:",
                  lastHarvest['land_location'], true),
              _buildInfoRow(Icons.calendar_today, "දින:",
                  "${lastHarvest['harvest_date'] ?? 'N/A'}"),
              _buildInfoRow(Icons.grass, "මුළු අස්වැන්න:",
                  formatQuantity(lastHarvest['total_yield'])),
              Divider(),
              Text("කොළ වර්ග අනුව අස්වැන්න:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _buildInfoRow(Icons.eco, "පීදුනු කොළ (P):",
                  formatQuantity(lastHarvest['p_yield'])),
              _buildInfoRow(Icons.eco, "කෙටි කොළ (KT):",
                  formatQuantity(lastHarvest['kt_yield'])),
              _buildInfoRow(Icons.eco, "රෑන් කෙටි කොළ (RKT):",
                  formatQuantity(lastHarvest['rkt_yield'])),
            ] else
              Text("අවසන් අස්වැන්න දත්ත නොමැත"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      [bool allowWrap = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label $value",
              style: TextStyle(fontSize: 16),
              maxLines: allowWrap ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYieldChart() {
    // If we have no data, show a message
    if (_filteredPredictions.isEmpty && _filteredActuals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text("තෝරාගත් මාසය සඳහා ප්‍රස්තාර දත්ත නොමැත"),
          ),
        ),
      );
    }

    // Create a map to align actual and predicted data by date
    Map<String, Map<String, dynamic>> dateDataMap = {};

    // Process actual data first
    for (var actual in _filteredActuals) {
      try {
        final date = DateTime.parse(actual['harvest_date'] ?? '2000-01-01');
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        if (!dateDataMap.containsKey(dateKey)) {
          dateDataMap[dateKey] = {
            'date': date,
            'dateLabel':
                DateFormat('dd/MM').format(date), // Store formatted date
            'actual_p': 0.0,
            'actual_kt': 0.0,
            'actual_rkt': 0.0,
            'predicted_p': 0.0,
            'predicted_kt': 0.0,
            'predicted_rkt': 0.0,
          };
        }

        // Parse values safely
        double pYield = _parseDouble(actual['p_yield']);
        double ktYield = _parseDouble(actual['kt_yield']);
        double rktYield = _parseDouble(actual['rkt_yield']);

        dateDataMap[dateKey]!['actual_p'] += pYield;
        dateDataMap[dateKey]!['actual_kt'] += ktYield;
        dateDataMap[dateKey]!['actual_rkt'] += rktYield;
      } catch (e) {
        print('Error processing actual: $e');
      }
    }

    // Process predicted data
    for (var pred in _filteredPredictions) {
      try {
        final date =
            DateTime.parse(pred['expected_harvest_date'] ?? '2000-01-01');
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        if (!dateDataMap.containsKey(dateKey)) {
          dateDataMap[dateKey] = {
            'date': date,
            'dateLabel':
                DateFormat('dd/MM').format(date), // Store formatted date
            'actual_p': 0.0,
            'actual_kt': 0.0,
            'actual_rkt': 0.0,
            'predicted_p': 0.0,
            'predicted_kt': 0.0,
            'predicted_rkt': 0.0,
          };
        }

        // Parse values safely
        double pYield = _parseDouble(pred['predicted_p']);
        double ktYield = _parseDouble(pred['predicted_kt']);
        double rktYield = _parseDouble(pred['predicted_rkt']);

        dateDataMap[dateKey]!['predicted_p'] += pYield;
        dateDataMap[dateKey]!['predicted_kt'] += ktYield;
        dateDataMap[dateKey]!['predicted_rkt'] += rktYield;
      } catch (e) {
        print('Error processing prediction: $e');
      }
    }

    // Sort dates for sequential display
    List<String> sortedDates = dateDataMap.keys.toList()..sort();

    // Create spots for chart and prepare date labels
    List<FlSpot> predictedPSpots = [];
    List<FlSpot> predictedKtSpots = [];
    List<FlSpot> predictedRktSpots = [];

    List<FlSpot> actualPSpots = [];
    List<FlSpot> actualKtSpots = [];
    List<FlSpot> actualRktSpots = [];

    // Clear and update date labels
    _weekLabels = [];

    for (var i = 0; i < sortedDates.length; i++) {
      final dateKey = sortedDates[i];
      final data = dateDataMap[dateKey]!;

      // Add the formatted date label
      _weekLabels.add(data['dateLabel']);

      predictedPSpots.add(FlSpot(i.toDouble(), data['predicted_p']));
      predictedKtSpots.add(FlSpot(i.toDouble(), data['predicted_kt']));
      predictedRktSpots.add(FlSpot(i.toDouble(), data['predicted_rkt']));

      actualPSpots.add(FlSpot(i.toDouble(), data['actual_p']));
      actualKtSpots.add(FlSpot(i.toDouble(), data['actual_kt']));
      actualRktSpots.add(FlSpot(i.toDouble(), data['actual_rkt']));
    }

    // Find max Y value for scaling
    double maxY = 0;
    for (var spots in [
      predictedPSpots,
      predictedKtSpots,
      predictedRktSpots,
      actualPSpots,
      actualKtSpots,
      actualRktSpots
    ]) {
      for (var spot in spots) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }

    // Round up to nearest 5K for better y-axis intervals
    maxY = maxY == 0 ? 30000 : (((maxY / 5000).ceil()) * 5000).toDouble();

    // Ensure maxY is at least 30K for consistent scale
    maxY = max(maxY, 30000);

    // Get month name
    final months = [
      'ජනවාරි',
      'පෙබරවාරි',
      'මාර්තු',
      'අප්‍රේල්',
      'මැයි',
      'ජූනි',
      'ජූලි',
      'අගෝස්තු',
      'සැප්තැම්බර්',
      'ඔක්තෝබර්',
      'නොවැම්බර්',
      'දෙසැම්බර්'
    ];
    final monthName = months[_selectedMonth - 1];

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
                Icon(Icons.show_chart, color: Colors.purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "පුරෝකථන සහ සත්‍ය අස්වැන්න සංසන්දනය ($monthName $_selectedYear)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: max(sortedDates.length * 100.0,
                      MediaQuery.of(context).size.width - 64),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _weekLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _weekLabels[
                                        index], // Use the date labels directly
                                    style: TextStyle(
                                      color: Color(0xff68737d),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10, // Smaller font for dates
                                    ),
                                  ),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5000, // Set interval to 5K
                            getTitlesWidget: (value, meta) {
                              // Format as 0, 5K, 10K, etc.
                              return Text(
                                formatLargeNumber(value),
                                style: TextStyle(
                                  color: Color(0xff67727d),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: const Color(0xff37434d), width: 1),
                      ),
                      minX: 0,
                      maxX: (sortedDates.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      clipData: FlClipData.all(), // Prevent line overflow
                      lineBarsData: [
                        // Predicted P line
                        LineChartBarData(
                          spots: predictedPSpots,
                          isCurved: true,
                          color: Colors.green.withOpacity(0.7),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                          dashArray: [5, 5], // Dashed line for predictions
                        ),
                        // Predicted KT line
                        LineChartBarData(
                          spots: predictedKtSpots,
                          isCurved: true,
                          color: Colors.blue.withOpacity(0.7),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                          dashArray: [5, 5], // Dashed line for predictions
                        ),
                        // Predicted RKT line
                        LineChartBarData(
                          spots: predictedRktSpots,
                          isCurved: true,
                          color: Colors.red.withOpacity(0.7),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                          dashArray: [5, 5], // Dashed line for predictions
                        ),
                        // Actual P line
                        LineChartBarData(
                          spots: actualPSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Actual KT line
                        LineChartBarData(
                          spots: actualKtSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Actual RKT line
                        LineChartBarData(
                          spots: actualRktSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("සටහන:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(
                        "පුරෝකථන P", Colors.green.withOpacity(0.7), true),
                    SizedBox(width: 16),
                    _buildLegendItem("සත්‍ය P", Colors.green),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _buildLegendItem(
                        "පුරෝකථන KT", Colors.blue.withOpacity(0.7), true),
                    SizedBox(width: 16),
                    _buildLegendItem("සත්‍ය KT", Colors.blue),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _buildLegendItem(
                        "පුරෝකථන RKT", Colors.red.withOpacity(0.7), true),
                    SizedBox(width: 16),
                    _buildLegendItem("සත්‍ය RKT", Colors.red),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildLegendItem(String label, Color color, [bool isDashed = false]) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            border: isDashed
                ? Border(
                    bottom: BorderSide(
                      color: color,
                      width: 3,
                      style: BorderStyle.solid,
                    ),
                  )
                : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                  size: Size(20, 3),
                )
              : null,
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // Helper function to get max of two values
  double max(double a, double b) {
    return a > b ? a : b;
  }

  Widget _buildAddHarvestForm() {
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
                  Icon(Icons.add_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "නව අස්වැන්න එකතු කරන්න:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _harvestDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _harvestDate = picked);
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'අස්වනු දින',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd').format(_harvestDate),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'අස්වනු දින අවශ්‍යයි' : null,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'මුළු අස්වැන්න (ගණන)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grass),
                  suffixText: 'K',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'මුළු අස්වැන්න අවශ්‍යයි';
                  }
                  if (double.tryParse(value) == null) {
                    return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                  }
                  return null;
                },
                onSaved: (value) => _totalYield = double.parse(value!),
              ),
              SizedBox(height: 16),
              Text(
                "අස්වැන්න වර්ගීකරණය (අමතර):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'P (ගණන)',
                        border: OutlineInputBorder(),
                        suffixText: 'K',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) =>
                          _pYield = value!.isEmpty ? 0 : double.parse(value),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'KT (ගණන)',
                        border: OutlineInputBorder(),
                        suffixText: 'K',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) =>
                          _ktYield = value!.isEmpty ? 0 : double.parse(value),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'RKT (ගණන)',
                        border: OutlineInputBorder(),
                        suffixText: 'K',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) =>
                          _rktYield = value!.isEmpty ? 0 : double.parse(value),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addHarvest,
                  icon: Icon(Icons.save),
                  label: Text('අස්වැන්න එකතු කරන්න'),
                  style: ElevatedButton.styleFrom(
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
}

// Custom painter for dashed lines in the legend
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    double dashWidth = 4, dashSpace = 3, startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
