import '../models/betel_bed_model.dart';

class BetelBedSampleData {
  // List of sample betel beds
  static List<BetelBed> getSampleBeds() {
    return [
      BetelBed(
        id: 'bed001',
        name: 'මගේ ප්‍රධාන බුලත් වගාව',
        location: 'කළුතර, දකුණු පළාත',
        imageUrl: 'assets/images/beds/betel_bed1.jpg',
        plantedDate: DateTime.now().subtract(const Duration(days: 120)),
        betelType: 'රතු බුලත්',
        areaSize: 25.0,
        plantCount: 200,
        sameBedCount: 2,
        status: BetelBedStatus.needsFertilizing,
        fertilizeHistory: [
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 35)),
            fertilizerType: 'කාබනික පොහොර',
            quantity: 5.0,
            notes: 'ගස් වල වර්ධනය හොඳයි',
          ),
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 65)),
            fertilizerType: 'NPK මිශ්‍රණය',
            quantity: 3.5,
            notes: 'කොළ පැහැය හොඳින් පවතී',
          ),
        ],
        harvestHistory: [
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 18)),
            leavesCount: 350,
            weight: 5.2,
            revenueEarned: 4200.0,
            quality: 'A',
            notes: 'හොඳ තත්වයේ අස්වැන්නක්',
          ),
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 36)),
            leavesCount: 325,
            weight: 4.8,
            revenueEarned: 3800.0,
            quality: 'A',
          ),
        ],
      ),
      BetelBed(
        id: 'bed002',
        name: 'නව කොළ බුලත් වගාව',
        location: 'අනමඩුව, වයඹ පළාත',
        imageUrl: 'assets/images/beds/betel_bed2.jpg',
        plantedDate: DateTime.now().subtract(const Duration(days: 45)),
        betelType: 'කොළ බුලත්',
        areaSize: 18.0,
        plantCount: 150,
        sameBedCount: 1,
        status: BetelBedStatus.recentlyFertilized,
        fertilizeHistory: [
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 5)),
            fertilizerType: 'යූරියා',
            quantity: 2.0,
            notes: 'පළමු පොහොර යෙදීම',
          ),
        ],
        harvestHistory: [],
      ),
      BetelBed(
        id: 'bed003',
        name: 'සුදු බුලත් විශේෂ වගාව',
        location: 'කුරුණෑගල, වයඹ පළාත',
        imageUrl: 'assets/images/beds/betel_bed3.jpg',
        plantedDate: DateTime.now().subtract(const Duration(days: 180)),
        betelType: 'සුදු බුලත්',
        areaSize: 30.0,
        plantCount: 250,
        sameBedCount: 3,
        status: BetelBedStatus.readyToHarvest,
        fertilizeHistory: [
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 20)),
            fertilizerType: 'කාබනික පොහොර',
            quantity: 6.0,
          ),
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 50)),
            fertilizerType: 'NPK මිශ්‍රණය',
            quantity: 4.0,
          ),
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 80)),
            fertilizerType: 'යූරියා',
            quantity: 3.0,
          ),
        ],
        harvestHistory: [
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 17)),
            leavesCount: 400,
            weight: 6.0,
            revenueEarned: 5000.0,
            quality: 'A+',
            notes: 'ඉහළ ගුණාත්මක බවින් යුක්ත අස්වැන්නක්',
          ),
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 35)),
            leavesCount: 380,
            weight: 5.5,
            revenueEarned: 4700.0,
            quality: 'A',
          ),
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 53)),
            leavesCount: 350,
            weight: 5.2,
            revenueEarned: 4200.0,
            quality: 'B+',
          ),
        ],
      ),
      BetelBed(
        id: 'bed004',
        name: 'පවුල් බුලත් වගාව',
        location: 'පුත්තලම, වයඹ පළාත',
        imageUrl: 'assets/images/beds/betel_bed4.jpg',
        plantedDate: DateTime.now().subtract(const Duration(days: 90)),
        betelType: 'මිශ්‍ර බුලත්',
        areaSize: 15.0,
        plantCount: 120,
        sameBedCount: 1,
        status: BetelBedStatus.needsWatering,
        fertilizeHistory: [
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 15)),
            fertilizerType: 'කාබනික පොහොර',
            quantity: 3.0,
          ),
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 45)),
            fertilizerType: 'යූරියා',
            quantity: 2.0,
          ),
        ],
        harvestHistory: [
          HarvestRecord(
            date: DateTime.now().subtract(const Duration(days: 3)),
            leavesCount: 200,
            weight: 3.0,
            revenueEarned: 2500.0,
            quality: 'B',
          ),
        ],
      ),
      BetelBed(
        id: 'bed005',
        name: 'පරීක්ෂණාත්මක බුලත් වගාව',
        location: 'පානදුර, බස්නාහිර පළාත',
        imageUrl: 'assets/images/beds/betel_bed5.jpg',
        plantedDate: DateTime.now().subtract(const Duration(days: 60)),
        betelType: 'හයිබ්‍රිඩ් බුලත්',
        areaSize: 10.0,
        plantCount: 80,
        sameBedCount: 1,
        status: BetelBedStatus.healthy,
        fertilizeHistory: [
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 10)),
            fertilizerType: 'විශේෂ පොහොර මිශ්‍රණය',
            quantity: 2.0,
            notes: 'පර්යේෂණාත්මක පොහොර මිශ්‍රණය',
          ),
          FertilizeRecord(
            date: DateTime.now().subtract(const Duration(days: 30)),
            fertilizerType: 'NPK මිශ්‍රණය',
            quantity: 1.5,
          ),
        ],
        harvestHistory: [],
      ),
    ];
  }
}