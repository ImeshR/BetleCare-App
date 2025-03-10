import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/user_provider.dart';
import 'package:betlecare/services/supabase_service.dart';

import '../../widgets/appbar/app_bar.dart';

class ManualLandMeasurementPage extends StatefulWidget {
  const ManualLandMeasurementPage({Key? key}) : super(key: key);

  @override
  _ManualLandMeasurementPageState createState() =>
      _ManualLandMeasurementPageState();
}

class _ManualLandMeasurementPageState extends State<ManualLandMeasurementPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final List<LatLng> _polygonPoints = [];
  int _polygonIdCounter = 1;
  int _markerIdCounter = 1;
  double? _area;
  LatLng? _currentLocation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker_$_markerIdCounter'),
          position: point,
        ),
      );
      _markerIdCounter++;
      _polygonPoints.add(point);
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    setState(() {
      _polygons.clear();
      _polygons.add(
        Polygon(
          polygonId: PolygonId('polygon_$_polygonIdCounter'),
          points: _polygonPoints,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.1),
        ),
      );
    });
  }

  void _calculateArea() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'කරුණාකර ඉඩම් මැනීම ගණනය කිරීමට අවම වශයෙන් ලක්ෂ්‍ය 3 ක් එක් කරන්න.'),
        ),
      );
      return;
    }

    double area = 0;
    for (int i = 0; i < _polygonPoints.length; i++) {
      int j = (i + 1) % _polygonPoints.length;
      area += _polygonPoints[i].latitude * _polygonPoints[j].longitude -
          _polygonPoints[j].latitude * _polygonPoints[i].longitude;
    }
    area = (area.abs() / 2) *
        111319.9 *
        111319.9 *
        0.000247105; // Convert to acres

    setState(() {
      _area = area;
    });
  }

  void _resetMeasurement() {
    setState(() {
      _markers.clear();
      _polygons.clear();
      _polygonPoints.clear();
      _markerIdCounter = 1;
      _area = null;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
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
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'ස්ථානය'),
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

  Future<void> _saveLandMeasurement() async {
    if (_area == null || _polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('වලංගු මිනුමක් නොමැත. කරුණාකර නැවත මනින්න.')),
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
        'location': _locationController.text,
        'area': _area,
        'coordinates': _polygonPoints
            .map((point) => [point.latitude, point.longitude])
            .toList(),
      };

      print("Saving land measurement: $landData");

      final result = await supabaseService.create("land_size", landData);
      print("Saved land measurement: $result");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඉඩම් මැනුම සාර්ථකව සුරකින ලදී')),
      );

      setState(() {
        _nameController.clear();
        _locationController.clear();
        _resetMeasurement();
      });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving land measurement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ඉඩම් මැනුම සුරැකීමේ දෝෂයක්.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? const LatLng(0, 0),
                  zoom: 14.4746,
                ),
                markers: _markers,
                polygons: _polygons,
                onTap: _addMarker,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 72,
                child: _area != null
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'ගණනය කළ ඉඩම් මැනීම: ${_area!.toStringAsFixed(2)} අක්කර',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _calculateArea,
                  backgroundColor: Colors.blue[100],
                  heroTag: 'calculate',
                  child: const Icon(Icons.calculate),
                  tooltip: 'වර්ගඵලය ගණනය කරන්න',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _resetMeasurement,
                  backgroundColor: Colors.green[100],
                  heroTag: 'reset',
                  child: const Icon(Icons.refresh),
                  tooltip: 'නැවත සකසන්න',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _showSaveModal,
                  backgroundColor: Colors.orange[100],
                  heroTag: 'save',
                  child: const Icon(Icons.save),
                  tooltip: 'සුරකින්න',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
