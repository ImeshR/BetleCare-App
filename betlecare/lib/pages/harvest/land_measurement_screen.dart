import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:betlecare/services/supabase_service.dart';
import 'package:betlecare/widgets/appbar/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/user_provider.dart';

class LandMeasurementScreen extends StatefulWidget {
  const LandMeasurementScreen({Key? key}) : super(key: key);

  @override
  _LandMeasurementScreenState createState() => _LandMeasurementScreenState();
}

class _LandMeasurementScreenState extends State<LandMeasurementScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _polygonPoints = [];
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  bool _isRecording = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  double? _area;

  final TextEditingController _nameController = TextEditingController();

  String? _selectedLocation;

  // Map of locations with Sinhala display names and English values
  final Map<String, String> _locations = {
    'Puttalam': 'පුත්තලම',
    'Anamaduwa': 'අනමඩුව',
    'Kurunegala': 'කුරුණෑගල',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ස්ථාන සේවා අක්රිය කර ඇත. කරුණාකර සේවාවන් සක්රිය කරන්න')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ස්ථාන අවසර ප්රතික්ෂේප කර ඇත')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'ස්ථාන අවසර ස්ථිරවම ප්රතික්ෂේප කර ඇත, අපට අවසර ඉල්ලීමට නොහැක.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      _updateCameraPosition(position);
    } catch (e) {
      print("වත්මන් ස්ථානය ලබා ගැනීමේ දෝෂයක්: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'වත්මන් ස්ථානය ලබා ගැනීමට අසමත් විය. කරුණාකර නැවත උත්සාහ කරන්න.')),
      );
    }
  }

  void _updateCameraPosition(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18,
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _polygonPoints.clear();
      _polygons.clear();
      _polylines.clear();
      _area = null;
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _polygonPoints.add(LatLng(position.latitude, position.longitude));
        _updatePolygon();
        _updatePolyline();
      });
      _updateCameraPosition(position);
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _positionStreamSubscription?.cancel();
    _calculateArea();
  }

  void _updatePolygon() {
    _polygons.clear();
    if (_polygonPoints.length >= 3) {
      _polygons.add(Polygon(
        polygonId: const PolygonId('land'),
        points: _polygonPoints,
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.3),
      ));
    }
  }

  void _updatePolyline() {
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('landBoundary'),
      points: _polygonPoints,
      color: Colors.blue,
      width: 3,
    ));
  }

  void _calculateArea() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'වර්ගඵලය ගණනය කිරීමට ප්රමාණවත් ලක්ෂ නැත. කරුණාකර සම්පූර්ණ ඉඩම වටා ඇවිදින්න.')),
      );
      return;
    }

    double area = 0;
    for (int i = 0; i < _polygonPoints.length; i++) {
      int j = (i + 1) % _polygonPoints.length;
      area += _polygonPoints[i].latitude * _polygonPoints[j].longitude -
          _polygonPoints[j].latitude * _polygonPoints[i].longitude;
    }
    area = (area.abs() * 111319.9 * 111319.9) / 2;
    double areaInAcres = area * 0.000247105;

    setState(() {
      _area = areaInAcres;
    });

    _showSaveModal();
  }

  Future<void> _saveLandMeasurement() async {
    if (_area == null || _polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('වලංගු මිනුමක් නොමැත. කරුණාකර නැවත මනින්න.')),
      );
      return;
    }

    if (_selectedLocation == null || _selectedLocation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ස්ථානයක් තෝරන්න.')),
      );
      return;
    }

    try {
      final supabaseService = await SupabaseService.init();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('පරිශීලක හඳුනාගත නොහැක. කරුණාකර නැවත පුරනය වන්න.')),
        );
        return;
      }

      final landData = {
        'user_id': userId,
        'name': _nameController.text,
        'location': _selectedLocation,
        'area': _area!.toStringAsFixed(2),
        'coordinates': _polygonPoints
            .map((point) => [point.latitude, point.longitude])
            .toList(),
      };

      final result = await supabaseService.create("land_size", landData);
      print("Saved land measurement: $result");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඉඩම් මැනුම සාර්ථකව සුරකින ලදී')),
      );

      setState(() {
        _nameController.clear();
        _polygonPoints.clear();
        _polygons.clear();
        _polylines.clear();
        _area = null;
      });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving land measurement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඉඩම් මැනුම සුරැකීමේ දෝෂයක්.')),
      );
    }
  }

  void _showSaveModal() {
    if (_area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර පළමුව වර්ගඵලය ගණනය කරන්න.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ඉඩම් මැනුම් සුරකින්න'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ඉඩමේ නම'),
                ),
                SizedBox(height: 16),
                // Dropdown for location selection
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'ස්ථානය',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedLocation,
                  hint: Text('ස්ථානය තෝරන්න'),
                  isExpanded: true,
                  items: _locations.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key, // English value
                      child: Text(entry.value), // Sinhala display name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('වර්ගඵලය: ${_area!.toStringAsFixed(2)} අක්කර'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("අවලංගු කරන්න"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("සුරකින්න"),
              onPressed: () => _saveLandMeasurement(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const BasicAppbar(),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 18,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polygons: _polygons,
            polylines: _polylines,
          ),
          if (_area != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 72,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ගණනය කළ වර්ගඵලය: ${_area!.toStringAsFixed(2)} අක්කර',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 20.0, bottom: 100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              backgroundColor:
                  (_isRecording ? Colors.red[100]! : Colors.green[100]!),
              heroTag: 'recordToggle',
              child: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              tooltip: _isRecording ? 'නවත්වන්න' : 'ආරම්භ කරන්න',
            ),
            const SizedBox(height: 16),
            if (!_isRecording && _area != null)
              FloatingActionButton(
                onPressed: _showSaveModal,
                backgroundColor: Colors.orange[100]!,
                heroTag: 'save',
                child: const Icon(Icons.save),
                tooltip: 'සුරකින',
              ),
          ],
        ),
      ),
    );
  }
}
