import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditBedScreen extends StatefulWidget {
  final BetelBed bed;

  const EditBedScreen({super.key, required this.bed});

  @override
  State<EditBedScreen> createState() => _EditBedScreenState();
}

class _EditBedScreenState extends State<EditBedScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController; // Changed from locationController
  late TextEditingController _areaSizeController;
  late TextEditingController _plantCountController;
  late TextEditingController _sameBedCountController;
  late DateTime _plantedDate;
  File? _imageFile;
  String? _existingImagePath;
  
  final List<String> _betelTypes = ['රතු බුලත්', 'කොළ බුලත්', 'සුදු බුලත්', 'මිශ්‍ර බුලත්', 'හයිබ්‍රිඩ් බුලත්'];
  String? _selectedBetelType;
  
  // New district dropdown
  final List<String> _districts = ['පුත්තලම (Puttalam)', 'අනමඩුව (Anamaduwa)', 'කුරුණෑගල (Kurunegala)'];
  String? _selectedDistrict;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.bed.name);
    _addressController = TextEditingController(text: widget.bed.address); // Changed from location to address
    _areaSizeController = TextEditingController(text: widget.bed.areaSize.toString());
    _plantCountController = TextEditingController(text: widget.bed.plantCount.toString());
    _sameBedCountController = TextEditingController(text: widget.bed.sameBedCount.toString());
    _plantedDate = widget.bed.plantedDate;
    _selectedBetelType = widget.bed.betelType;
    _selectedDistrict = widget.bed.district; // Initialize district
    _existingImagePath = widget.bed.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose(); // Changed from locationController
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
      // If using existing image or new image is selected, form is valid
      if (_imageFile != null || _existingImagePath != null) {
        // Check if district is selected
        if (_selectedDistrict == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('කරුණාකර ප්‍රදේශය තෝරන්න')),
          );
          return false;
        }
        return true;
      } else {
        // No image selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('කරුණාකර රූපයක් තෝරන්න')),
        );
        return false;
      }
    }
    return false;
  }

  void _updateBed() {
    if (_validateForm()) {
      // Here you would normally update the database
      // For now, just show success and go back
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('බුලත් පඳුර සාර්ථකව යාවත්කාලීන කරන ලදී')),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'බුලත් පඳුර සංස්කරණය',
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
                        : _existingImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network( // Changed from Image.asset to Image.network
                                  _existingImagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  },
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
                
                // District Dropdown (New field)
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: InputDecoration(
                    labelText: 'ප්‍රදේශය',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: _districts.map((String district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර ප්‍රදේශය තෝරන්න';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Address Field (Changed from Location)
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'ලිපිනය',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'කරුණාකර ලිපිනය ඇතුළත් කරන්න';
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
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _updateBed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'යාවත්කාලීන කරන්න',
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