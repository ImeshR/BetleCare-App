import 'package:flutter/material.dart';

class LocationDropdown extends StatelessWidget {
  final String selectedLocation;
  final Map<String, Map<String, double>> locations;
  final Function(String?) onLocationChanged;

  const LocationDropdown({
    super.key,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedLocation,
          items: locations.keys
              .map((location) => DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null && value != selectedLocation) {
              onLocationChanged(value);
            }
          },
        ),
      ),
    );
  }
}