import 'dart:math';

class SoilService {
  static const Map<String, List<String>> compatibleSoilsMapping = {
    "Kurunegala": ["Reddish Brown Earth", "Loamy Soil"],
    "Puttalam": ["Sandy Loam Soil", "Loamy Soil"],
    "Anamaduwa": ["Alluvial Soil", "Reddish Brown Earth"]
  };

  static String analyzeSoilType(String location) {
    if (!compatibleSoilsMapping.containsKey(location)) {
      return "Unknown Soil Type";
    }

    final soilTypes = compatibleSoilsMapping[location]!;
    final random = Random();

    // Generate a random index to select a soil type
    final index = random.nextInt(soilTypes.length);

    return soilTypes[index];
  }
}
