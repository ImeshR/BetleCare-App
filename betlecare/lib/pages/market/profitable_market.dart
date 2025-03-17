import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfitableMarketScreen extends StatefulWidget {
  const ProfitableMarketScreen({super.key});

  @override
  _ProfitableMarketScreenState createState() => _ProfitableMarketScreenState();
}

class _ProfitableMarketScreenState extends State<ProfitableMarketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedType;
  String? _selectedSize;
  String? _selectedQuality;

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final requestBody = {
        'Date': _dateController.text,
        'No_of_Leaves': _quantityController.text,
        'Leaf_Type': _selectedType,
        'Leaf_Size': _selectedSize,
        'Quality_Grade': _selectedQuality,
      };

      final apiUrl =
          '${dotenv.env['MARKET_PREDICT_BASE_URL']!}/predict-location';
      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final location = data['location'];
        setState(() {
          _isLoading = false;
        });
        _showPopup(location);
      } else {
        setState(() {
          _isLoading = false;
        });
        dev.log('Error: ${response.statusCode}');
      }
    }
  }

  void _showPopup(location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/eshan/LM1.png', height: 150),
              const SizedBox(height: 16),
              Text(
                'අපේක්ෂිත ඉල්ලුම් ඇති වෙළඳපොල : $location',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _dateController.clear();
    _quantityController.clear();
    _selectedType = null;
    _selectedSize = null;
    _selectedQuality = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'ලභාදායී වෙළඳපොල',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildDatePicker('දිනය', _dateController),
                        _buildNumberInputField('කොළ ගණන', _quantityController),
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
                        _buildDropdownField(
                            'කොලයේ ප්‍රමාණය',
                            [
                              const MapEntry('කුඩා', 'Small'),
                              const MapEntry('මධ්‍යම', 'Medium'),
                              const MapEntry('විශාල', 'Large'),
                            ],
                            (val) => setState(() => _selectedSize = val),
                            _selectedSize),
                        _buildDropdownField(
                            'ගුණාත්මක මට්ටම',
                            [
                              const MapEntry('අළු', 'Ash'),
                              const MapEntry('අදුරැ', 'Dark'),
                            ],
                            (val) => setState(() => _selectedQuality = val),
                            _selectedQuality),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const SizedBox.shrink()
                      : ElevatedButton(
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
                            'වෙළඳපොල පුරෝකථනය කරන්න',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
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
        validator: (value) =>
            value!.isEmpty ? 'කරුණාකර දිනයක් ඇතුළත් කරන්න' : null,
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

  Widget _buildNumberInputField(
      String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.green.shade100,
        ),
        validator: (value) => value!.isEmpty
            ? 'කරුණාකර සංඛ්‍යාත්මක වටිනාකමක් ඇතුළත් කරන්න'
            : null,
      ),
    );
  }

  // Widget _buildDropdownField(String title, List<String> options,
  //     Function(String?) onChanged, String? selectedValue) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(
  //       vertical: 8,
  //     ),
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
  //       validator: (value) => value == null ? 'කරුණාකර මතයක් තෝරන්න' : null,
  //     ),
  //   );
  // }

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
}
