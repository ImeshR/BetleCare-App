class BetelBed {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final DateTime plantedDate;
  final String betelType;
  final double areaSize; // in square meters
  final int plantCount;
  final int sameBedCount; // how many similar beds in same location
  final List<FertilizeRecord> fertilizeHistory;
  final List<HarvestRecord> harvestHistory;
  final BetelBedStatus status;

  BetelBed({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.plantedDate,
    required this.betelType,
    required this.areaSize,
    required this.plantCount,
    required this.sameBedCount,
    required this.fertilizeHistory,
    required this.harvestHistory,
    required this.status,
  });

  // Get the age of plants in days
  int get ageInDays {
    return DateTime.now().difference(plantedDate).inDays;
  }

  // Next required action based on status
  String get nextAction {
    switch (status) {
      case BetelBedStatus.needsFertilizing:
        return "පොහොර යෙදීම අවශ්‍යයි";
      case BetelBedStatus.readyToHarvest:
        return "අස්වනු නෙලීමට සූදානම්";
      case BetelBedStatus.needsWatering:
        return "ජලය යෙදීම අවශ්‍යයි";
      case BetelBedStatus.recentlyFertilized:
        return "මෑතදී පොහොර යොදා ඇත";
      case BetelBedStatus.recentlyHarvested:
        return "මෑතදී අස්වැන්න නෙලා ඇත";
      case BetelBedStatus.healthy:
        return "හොඳ තත්වයේ පවතී";
      case BetelBedStatus.diseased:
        return "රෝගී තත්වයේ පවතී";
      default:
        return "සාමාන්‍ය";
    }
  }

  // Days until next fertilizing
  int get daysUntilNextFertilizing {
    if (fertilizeHistory.isEmpty) {
      return 0;
    }
    final lastFertilize = fertilizeHistory.last.date;
    const fertilizingInterval = 30; // Typically every 30 days
    final nextFertilizeDate = lastFertilize.add(const Duration(days: fertilizingInterval));
    return nextFertilizeDate.difference(DateTime.now()).inDays;
  }

  // Days until next harvesting
  int get daysUntilNextHarvesting {
    // If never harvested, calculate from planting date (typically 90 days for first harvest)
    if (harvestHistory.isEmpty) {
      const firstHarvestDays = 90;
      final firstHarvestDate = plantedDate.add(const Duration(days: firstHarvestDays));
      return firstHarvestDate.difference(DateTime.now()).inDays;
    }
    
    // If previously harvested, calculate from last harvest (typically every 15-20 days)
    const harvestInterval = 18; // Assuming every 18 days after first harvest
    final lastHarvest = harvestHistory.last.date;
    final nextHarvestDate = lastHarvest.add(const Duration(days: harvestInterval));
    return nextHarvestDate.difference(DateTime.now()).inDays;
  }
}

class FertilizeRecord {
  final String? id; // ID from Supabase
  final DateTime date;
  final String fertilizerType;
  final double quantity; // in kg or appropriate unit
  final String notes;

  FertilizeRecord({
    this.id,
    required this.date,
    required this.fertilizerType,
    required this.quantity,
    this.notes = '',
  });
}

class HarvestRecord {
  final String? id; // ID from Supabase
  final DateTime date;
  final int leavesCount;
  final double weight; // in kg
  final double revenueEarned; // in LKR
  final String quality; // 'A', 'B', 'C' etc.
  final String notes;

  HarvestRecord({
    this.id,
    required this.date,
    required this.leavesCount,
    required this.weight,
    required this.revenueEarned,
    required this.quality,
    this.notes = '',
  });
}

enum BetelBedStatus {
  healthy,
  needsFertilizing,
  needsWatering,
  readyToHarvest,
  recentlyFertilized,
  recentlyHarvested,
  diseased,
}