import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddNewBedScreen extends StatefulWidget {
  const AddNewBedScreen({super.key});

  @override
  State<AddNewBedScreen> createState() => _AddNewBedScreenState();
}

class _AddNewBedScreenState extends State<AddNewBedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _betelTypeController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _plantCountController = TextEditingController();
  final _sameBedCountController = TextEditingController();
  DateTime _plantedDate = DateTime.now();
  File? _imageFile;
  final List<String> _betelTypes = ['රතු බුලත්', 'කොළ බුලත්', 'සුදු බුලත්', 'මිශ්‍ර බුලත්', 'හයිබ්‍රිඩ් බුලත්'];
  String? _selectedBetelType;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _betelTypeController.dispose();
    _areaSizeController.dispose();
    _plantCountController.dispose();
    _sameBedCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle error
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('රූපය තේරීමේ දෝෂයකි')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _plantedDate) {
      setState(() {
        _plantedDate = picked;
      });
    }
  }

  bool _validateForm() {
    if (_formKey.currentState!.validate()) {
      // Check if an image is selected
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('කරුණාකර රූපයක් තෝරන්න')),
        );
        return false;
      }
      
      return true;
    }
    return false;
  }

  void _saveBed() {
    if (_validateForm()) {
      // Here you would normally save to a database
      // For now, just show success and go back
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('නව බුලත් පඳුර සාර්ථකව එකතු කරන ලදී')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'නව බුලත් පඳුරක් එකතු කරන්න',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image selection
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'රූපයක් තෝරන්න',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form Fields
                const Text(
                  'මූලික තොරතුරු',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'පඳුරේ නම',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.spa),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර පඳුරේ නම ඇතුළත් කරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'ස්ථානය',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර ස්ථානය ඇතුළත් කරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Betel Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBetelType,
                  decoration: InputDecoration(
                    labelText: 'බුලත් වර්ගය',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.grass),
                  ),
                  items: _betelTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBetelType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර බුලත් වර්ගය තෝරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Date Picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'වගා කළ දිනය',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_plantedDate.year}-${_plantedDate.month.toString().padLeft(2, '0')}-${_plantedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Additional Details
                const Text(
                  'අමතර තොරතුරු',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Area Size Field
                TextFormField(
                  controller: _areaSizeController,
                  decoration: InputDecoration(
                    labelText: 'ප්‍රමාණය (m²)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර ප්‍රමාණය ඇතුළත් කරන්න';
                    }
                    if (double.tryParse(value) == null) {
                      return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Plant Count Field
                TextFormField(
                  controller: _plantCountController,
                  decoration: InputDecoration(
                    labelText: 'පැළ ගණන',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.eco),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර පැළ ගණන ඇතුළත් කරන්න';
                    }
                    if (int.tryParse(value) == null) {
                      return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Similar Bed Count Field
                TextFormField(
                  controller: _sameBedCountController,
                  decoration: InputDecoration(
                    labelText: 'සමාන පඳුරු ගණන',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.content_copy),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර සමාන පඳුරු ගණන ඇතුළත් කරන්න';
                    }
                    if (int.tryParse(value) == null) {
                      return 'කරුණාකර වලංගු අගයක් ඇතුළත් කරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveBed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'සුරකින්න',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}