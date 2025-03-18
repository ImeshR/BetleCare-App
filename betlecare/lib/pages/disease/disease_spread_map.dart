import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/user_provider.dart';
import 'package:betlecare/services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';

class DiseaseReportPage extends StatefulWidget {
  const DiseaseReportPage({Key? key}) : super(key: key);

  @override
  _DiseaseReportPageState createState() => _DiseaseReportPageState();
}

class _DiseaseReportPageState extends State<DiseaseReportPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  String? _selectedDisease;
  String? _currentCity = ""; // Variable to store the nearest city
  final TextEditingController _cityController = TextEditingController();
  String? _mapApiKey;

  List<String> _citySuggestions = []; // List to store city suggestions
  List<LatLng> _cityCoordinates = []; // List to store city coordinates
  final double maxDistanceInKm = 50.0; // Max allowed distance in kilometers
  List<Map<String, dynamic>> _diseaseReports =
      []; // List to hold disease reports
  Set<Marker> _markers = {}; // Set of markers to display on map

  @override
  void initState() {
    super.initState();
    _mapApiKey = dotenv.env['MAP_API_KEY'];
    _getUserLocation();
    _loadDiseaseReports();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadDiseaseReports() async {
    try {
      final supabaseService = await SupabaseService.init();
      List<Map<String, dynamic>> reports =
          await supabaseService.getDiseaseReportsFromDate();

      // Update the state with fetched reports and create markers
      setState(() {
        _diseaseReports = reports;
        _markers = reports.map((report) {
          final LatLng position =
              LatLng(report['latitude'], report['longitude']);
          return Marker(
            markerId: MarkerId(report['id'].toString()),
            position: position,
            onTap: () {
              _showReportDetails(report);
            },
          );
        }).toSet();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading disease reports: $e')),
      );
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disease Report Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Disease: ${report['disease']}'),
              Text('Reported on: ${report['created_at']}'),
              Text('City: ${report['city']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permission is permanently denied.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
      _fetchNearestCity(); // Fetch the nearest city after getting location
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _fetchNearestCity() async {
    if (_currentLocation == null) return;

    // Use reverse geocoding to get the nearest city
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          _currentCity = placemarks[0].locality;
          _cityController.text = _currentCity!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching nearest city: $e')),
      );
    }
  }

  // Function to validate if the selected city is far from the current location
  Future<void> _validateCityDistance(String selectedCity) async {
    if (_currentLocation == null) return;

    // Use geocoding to get coordinates of the selected city
    try {
      List<Location> locations = await locationFromAddress(selectedCity);
      if (locations.isNotEmpty) {
        LatLng cityLocation =
            LatLng(locations[0].latitude, locations[0].longitude);

        // Calculate the distance
        double distanceInMeters = await Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          cityLocation.latitude,
          cityLocation.longitude,
        );
        double distanceInKm = distanceInMeters / 1000;

        // If the city is too far, show an error message
        if (distanceInKm > maxDistanceInKm) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Selected city is too far from your location!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error validating city distance: $e')),
      );
    }
  }

  // Function to show the popup dialog for entering city and disease
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('රෝග වාර්තා කිරීම'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown for disease selection
                DropdownButtonFormField<String>(
                  value: _selectedDisease,
                  decoration: const InputDecoration(
                    labelText: 'රෝගය තෝරන්න',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'පත්‍ර කුණු වීමේ රෝගය',
                    'දුඹුරු පැල්ලම්',
                    'කණාමැදිරි රෝගය',
                    'මකුළු රෝගය'
                  ].map((disease) {
                    return DropdownMenuItem<String>(
                      value: disease,
                      child: Text(disease),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedDisease = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // City Input Field
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'ආසන්නතම නගරය',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) async {
                    // Start filtering cities based on user input
                    if (text.isNotEmpty) {
                      _citySuggestions = await _getCitySuggestions(text);
                    }
                    setState(() {});
                  },
                ),
                // Display city suggestions
                if (_citySuggestions.isNotEmpty)
                  Column(
                    children: _citySuggestions.map((city) {
                      return ListTile(
                        title: Text(city),
                        onTap: () {
                          _cityController.text = city;
                          _validateCityDistance(
                              city); // Validate the selected city
                          Navigator.of(context).pop(); // Close dialog
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without submitting
              },
              child: const Text('අවලංගු කරන්න'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitReport();
                Navigator.of(context).pop(); // Close dialog after submitting
              },
              child: const Text('වාර්තා කරන්න'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _getCitySuggestions(String query) async {
    // You can use any service here to get cities that match the query
    // Here we are simply filtering a hardcoded list as an example
    List<String> cities = [
      'Colombo',
      'Kandy',
      'Galle',
      'Anuradhapura',
      'Negombo',
      'Matara',
    ];

    return cities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> _submitReport() async {
    if (_currentLocation == null ||
        _selectedDisease == null ||
        _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    try {
      final supabaseService = await SupabaseService.init();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      final reportData = {
        'user_id': userId,
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'disease': _selectedDisease!,
        'city': _cityController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabaseService.create('disease_reports', reportData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('සාර්ථකව රෝගය වාර්තා කරන ලදී!')),
      );

      setState(() {
        _selectedDisease = null;
        _cityController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('සාර්ථකව රෝගය වාර්තා කිරීමේදී දෝෂයක් ඇති විය: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 110,
            right: 10,
            child: GestureDetector(
              onTap: _showReportDialog,
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 30,
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
