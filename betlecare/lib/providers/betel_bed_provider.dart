import 'package:flutter/foundation.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/betel_bed_service.dart';

class BetelBedProvider with ChangeNotifier {
  final _betelBedService = BetelBedService();
  List<BetelBed> _beds = [];
  bool _isLoading = false;
  String? _error;

  List<BetelBed> get beds => _beds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBeds() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _beds = await _betelBedService.getBetelBeds();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteBed(String bedId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Call the service to delete the bed
      await _betelBedService.deleteBed(bedId);
      
      // Remove the bed from the local list
      _beds.removeWhere((bed) => bed.id == bedId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow; // Rethrow to allow proper error handling in UI
    }
  }
  
  Future<FertilizeRecord> addFertilizeRecord(String bedId, FertilizeRecord record) async {
    try {
      final newRecord = await _betelBedService.addFertilizeRecord(bedId, record);
      
      // Update the bed in the list
      final bedIndex = _beds.indexWhere((bed) => bed.id == bedId);
      if (bedIndex >= 0) {
        final updatedBed = _beds[bedIndex];
        final updatedFertilizeHistory = [...updatedBed.fertilizeHistory, newRecord];
        
        _beds[bedIndex] = BetelBed(
          id: updatedBed.id,
          name: updatedBed.name,
          address: updatedBed.address, // Changed from location to address
          district: updatedBed.district, // Added district field
          imageUrl: updatedBed.imageUrl,
          plantedDate: updatedBed.plantedDate,
          betelType: updatedBed.betelType,
          areaSize: updatedBed.areaSize,
          plantCount: updatedBed.plantCount,
          sameBedCount: updatedBed.sameBedCount,
          fertilizeHistory: updatedFertilizeHistory,
          harvestHistory: updatedBed.harvestHistory,
          status: BetelBedStatus.recentlyFertilized,
        );
        
        notifyListeners();
      }
      
      return newRecord;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<HarvestRecord> addHarvestRecord(String bedId, HarvestRecord record) async {
    try {
      final newRecord = await _betelBedService.addHarvestRecord(bedId, record);
      
      // Update the bed in the list
      final bedIndex = _beds.indexWhere((bed) => bed.id == bedId);
      if (bedIndex >= 0) {
        final updatedBed = _beds[bedIndex];
        final updatedHarvestHistory = [...updatedBed.harvestHistory, newRecord];
        
        _beds[bedIndex] = BetelBed(
          id: updatedBed.id,
          name: updatedBed.name,
          address: updatedBed.address, // Changed from location to address
          district: updatedBed.district, // Added district field
          imageUrl: updatedBed.imageUrl,
          plantedDate: updatedBed.plantedDate,
          betelType: updatedBed.betelType,
          areaSize: updatedBed.areaSize,
          plantCount: updatedBed.plantCount,
          sameBedCount: updatedBed.sameBedCount,
          fertilizeHistory: updatedBed.fertilizeHistory,
          harvestHistory: updatedHarvestHistory,
          status: BetelBedStatus.recentlyHarvested,
        );
        
        notifyListeners();
      }
      
      return newRecord;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> updateBedStatus(String bedId, BetelBedStatus status) async {
    try {
      await _betelBedService.updateBedStatus(bedId, status);
      
      // Update the bed in the list
      final bedIndex = _beds.indexWhere((bed) => bed.id == bedId);
      if (bedIndex >= 0) {
        final updatedBed = _beds[bedIndex];
        
        _beds[bedIndex] = BetelBed(
          id: updatedBed.id,
          name: updatedBed.name,
          address: updatedBed.address, // Changed from location to address
          district: updatedBed.district, // Added district field
          imageUrl: updatedBed.imageUrl,
          plantedDate: updatedBed.plantedDate,
          betelType: updatedBed.betelType,
          areaSize: updatedBed.areaSize,
          plantCount: updatedBed.plantCount,
          sameBedCount: updatedBed.sameBedCount,
          fertilizeHistory: updatedBed.fertilizeHistory,
          harvestHistory: updatedBed.harvestHistory,
          status: status,
        );
        
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Get stats for dashboard
  int get totalBeds => _beds.length;
  
  int get bedsNeedingAttention => _beds.where((bed) => 
    bed.status == BetelBedStatus.needsFertilizing || 
    bed.status == BetelBedStatus.needsWatering || 
    bed.status == BetelBedStatus.readyToHarvest ||
    bed.status == BetelBedStatus.diseased
  ).length;
  
  int get totalPlants => _beds.fold(0, (sum, bed) => sum + bed.plantCount);
  
  // Delete a bed

// Delete a bed - Improved to avoid widget ancestor error

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}