import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MarketVolatilityScreen extends StatefulWidget {
  const MarketVolatilityScreen({super.key});

  @override
  _MarketVolatilityScreenState createState() => _MarketVolatilityScreenState();
}

class _MarketVolatilityScreenState extends State<MarketVolatilityScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _selectedMarket;
  String? _selectedType;
  bool _showChart = false;
  List<FlSpot> chartData = [];
  List<String> xLabels = [];
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      setState(() {
        _showChart = false;
      });
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    DateTime startDate = DateTime.parse(_startDateController.text);
    DateTime endDate = DateTime.parse(_endDateController.text);
    Duration diff = endDate.difference(startDate);

    List<FlSpot> generatedData = [];
    List<String> labels = [];

    if (diff.inDays <= 60) {
      // 1-2 months: Show daily data
      for (int i = 0; i <= diff.inDays; i++) {
        DateTime date = startDate.add(Duration(days: i));
        generatedData.add(FlSpot(i.toDouble(), _randomYValue()));
        labels.add(DateFormat('MMM d').format(date));
      }
    } else if (diff.inDays <= 365) {
      // 2-12 months: Show weekly data
      for (int i = 0; i <= diff.inDays ~/ 7; i++) {
        DateTime date = startDate.add(Duration(days: i * 7));
        generatedData.add(FlSpot(i.toDouble(), _randomYValue()));
        labels.add(DateFormat('MMM d').format(date));
      }
    } else {
      // More than 12 months: Show monthly data
      for (int i = 0; i <= diff.inDays ~/ 30; i++) {
        DateTime date = DateTime(startDate.year, startDate.month + i, 1);
        generatedData.add(FlSpot(i.toDouble(), _randomYValue()));
        labels.add(DateFormat('MMM yyyy').format(date));
      }
    }

    //! add a delay
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      _showChart = true;
      _isLoading = false;
      chartData = generatedData;
      xLabels = labels;
    });
  }

  double _randomYValue() {
    return (5 + (20 * (DateTime.now().millisecondsSinceEpoch % 100) / 100))
        .clamp(0, 25)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'වෙළදපල විචලනය',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _showChart
                      ? SizedBox(
                          height: 300,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: chartData.length * 40, // Dynamic width
                              child: PriceLineChart(
                                  data: chartData, labels: xLabels),
                            ),
                          ),
                        )
                      : const Text(
                          "කරුණාකර දිතින් පරාසයක් ඇතුළත් කරන්න.",
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                  _buildDatePicker('ආරම්භක දිනය', _startDateController),
                  _buildDatePicker('අවසන් දිනය', _endDateController),
                  _buildDropdownField(
                      'වෙළඳපොල',
                      [
                        const MapEntry('කුළියාපිටිය', 'Kuliyapitiya'),
                        const MapEntry('නයිවල', 'Naiwala'),
                        const MapEntry('අපලාදෙණිය', 'Apaladeniya'),
                      ],
                      (val) => setState(() => _selectedMarket = val),
                      _selectedMarket),
                  _buildDropdownField(
                      'කොළ වර්ගය',
                      [
                        const MapEntry('පීදිච්ච', 'Peedichcha'),
                        const MapEntry('කොරිකන්', 'Korikan'),
                        const MapEntry('කෙටි', 'Keti'),
                        const MapEntry('රෑන් කෙටි', 'Raan Keti'),
                      ],
                      (val) => setState(() => _selectedType = val),
                      _selectedType),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      'විචලනය සොයන්න',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Indicator Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.green.shade100,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            setState(() {
              controller.text = pickedDate.toLocal().toString().split(' ')[0];
            });
          }
        },
      ),
    );
  }

  Widget _buildDropdownField(
      String title,
      List<MapEntry<String, String>> options,
      Function(String?) onChanged,
      String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: options
            .map((entry) => DropdownMenuItem(
                  value: entry.value,
                  child: Text(entry.key),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.green.shade100,
        ),
        dropdownColor: Colors.green.shade50,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
        validator: (value) => value == null ? 'කරුණාකර මතයක් තෝරන්න' : null,
      ),
    );
  }

  // Widget _buildDropdownField(
  //   String title,
  //   List<String> options,
  //   Function(String?) onChanged,
  //   String? selectedValue,
  // ) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: DropdownButtonFormField<String>(
  //       value: selectedValue,
  //       items: options
  //           .map((option) =>
  //               DropdownMenuItem(value: option, child: Text(option)))
  //           .toList(),
  //       onChanged: onChanged,
  //       decoration: InputDecoration(
  //         labelText: title,
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //         filled: true,
  //         fillColor: Colors.green.shade100,
  //       ),
  //       dropdownColor: Colors.green.shade50,
  //       style: const TextStyle(color: Colors.black87, fontSize: 16),
  //       icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
  //     ),
  //   );
  // }
}

class PriceLineChart extends StatelessWidget {
  final List<FlSpot> data;
  final List<String> labels;

  const PriceLineChart({super.key, required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 25,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < labels.length && index % 2 == 0) {
                  return Text(
                      labels[index]); // Show label only at every 2nd index
                }
                return const SizedBox();
              },
              interval: 2, // Increase gap between X-axis points
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .where((spot) =>
                    spot.x % 2 == 0) // Ensure data points are spaced by 2
                .toList(),
            isCurved: true,
            color: Colors.blue,
            dotData: FlDotData(show: true),
            barWidth: 2,
          ),
        ],
      ),
    );
  }
}
