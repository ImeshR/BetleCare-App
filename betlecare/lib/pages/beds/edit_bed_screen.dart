import 'package:betlecare/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:betlecare/services/betel_bed_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';

class EditBedScreen extends StatefulWidget {
  final BetelBed bed;

  const EditBedScreen({super.key, required this.bed});

  @override
  State<EditBedScreen> createState() => _EditBedScreenState();
}

class _EditBedScreenState extends State<EditBedScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _areaSizeController;
  late TextEditingController _plantCountController;
  late TextEditingController _sameBedCountController;
  late DateTime _plantedDate;
  File? _imageFile;
  String? _existingImagePath;
  bool _isLoading = false;

  final _betelBedService = BetelBedService();

  final List<String> _betelTypes = [
    'රට දළු',
    'මනේරු',
    'රතු බුලත්',
  ];
  String? _selectedBetelType;

  final List<String> _districts = [
    'පුත්තලම (Puttalam)',
    'අනමඩුව (Anamaduwa)',
    'කුරුණෑගල (Kurunegala)'
  ];
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.bed.name);
    _addressController = TextEditingController(text: widget.bed.address);
    _areaSizeController =
        TextEditingController(text: widget.bed.areaSize.toString());
    _plantCountController =
        TextEditingController(text: widget.bed.plantCount.toString());
    _sameBedCountController =
        TextEditingController(text: widget.bed.sameBedCount.toString());
    _plantedDate = widget.bed.plantedDate;
    _selectedBetelType = widget.bed.betelType;
    _selectedDistrict = widget.bed.district;
    _existingImagePath = widget.bed.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaSizeController.dispose();
    _plantCountController.dispose();
    _sameBedCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedFile =
          await imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
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

        // Check if betel type is selected
        if (_selectedBetelType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('කරුණාකර බුලත් වර්ගය තෝරන්න')),
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

  Future<void> _updateBed() async {
    if (_validateForm()) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Create an updated BetelBed object
        final updatedBed = BetelBed(
          id: widget.bed.id,
          name: _nameController.text,
          address: _addressController.text,
          district: _selectedDistrict!,
          imageUrl: _existingImagePath ??
              '', // Will be updated if new image is uploaded
          plantedDate: _plantedDate,
          betelType: _selectedBetelType!,
          areaSize: double.parse(_areaSizeController.text),
          plantCount: int.parse(_plantCountController.text),
          sameBedCount: int.parse(_sameBedCountController.text),
          fertilizeHistory: widget.bed.fertilizeHistory,
          harvestHistory: widget.bed.harvestHistory,
          status: widget.bed.status,
        );

        // Update the bed data in the database
        if (_imageFile != null) {
          // If there's a new image, upload it first and get the new URL
          // This is a theoretical implementation - your actual service might work differently
          final updatedBedWithImage = await _betelBedService.updateBedWithImage(
              updatedBed, _imageFile!);

          // Update the provider if used
          await _updateProvider();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('බුලත් වගාව සාර්ථකව යාවත්කාලීන කරන ලදී')),
          );

          // Return true to indicate successful update
          Navigator.pop(context, true);
        } else {
          // No new image, just update the bed data
          await _betelBedService.updateBed(updatedBed);

          // Update the provider if used
          await _updateProvider();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('බුලත් වගාව සාර්ථකව යාවත්කාලීන කරන ලදී')),
          );

          // Return true to indicate successful update
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Error updating bed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('යාවත්කාලීන කිරීමේ දෝෂයකි: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProvider() async {
    try {
      // If you're using a provider to manage state, update it
      final betelBedProvider =
          Provider.of<BetelBedProvider>(context, listen: false);
      await betelBedProvider.loadBeds();
    } catch (e) {
      print('Error updating provider: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'බුලත් වගාව සංස්කරණය',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                    child: Image.network(
                                      _existingImagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                        labelText: 'වගාවේ නම',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.spa),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'කරුණාකර වගාවේ නම ඇතුළත් කරන්න';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // District Dropdown
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

                    // Address Field
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
                        labelText: 'සමාන වගාවන් ගණන',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.content_copy),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'කරුණාකර සමාන වගාවන් ගණන ඇතුළත් කරන්න';
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
                        onPressed: _isLoading ? null : _updateBed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
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
          // Overlay loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2, // Home is selected
        onTabChange: (index) {
          if (index != 2) {
            // If not clicking the current tab
            // Create a replacement route to the MainPage with the correct tab index
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // First pop back to the main screen
              Navigator.of(context).pop();

              // Then push a replacement to force refresh the main page with the new index
              Navigator.of(context)
                  .pushReplacementNamed('/main', arguments: index);
            });
          }
        },
      ),
    );
  }
}
