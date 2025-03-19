import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BetelBedService {
  static final BetelBedService _instance = BetelBedService._internal();

  factory BetelBedService() {
    return _instance;
  }

  BetelBedService._internal();

  // get all betel
  Future<List<BetelBed>> getBetelBeds() async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final data = await supabase.client
          .from('betel_beds')
          .select('*, fertilize_history(*), harvest_history(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return data.map<BetelBed>((bed) {
        final fertilizeHistory =
            (bed['fertilize_history'] as List<dynamic>?)?.map((record) {
                  return FertilizeRecord(
                    id: record['id'],
                    date: DateTime.parse(record['date']),
                    fertilizerType: record['fertilizer_type'],
                    quantity: record['quantity'].toDouble(),
                    notes: record['notes'] ?? '',
                  );
                }).toList() ??
                [];

        final harvestHistory =
            (bed['harvest_history'] as List<dynamic>?)?.map((record) {
                  return HarvestRecord(
                    id: record['id'],
                    date: DateTime.parse(record['date']),
                    leavesCount: record['leaves_count'],
                    weight: record['weight'].toDouble(),
                    revenueEarned: record['revenue_earned'].toDouble(),
                    quality: record['quality'],
                    notes: record['notes'] ?? '',
                  );
                }).toList() ??
                [];

        return BetelBed(
          id: bed['id'],
          name: bed['name'],
          address: bed['address'],
          district: bed['district'],
          imageUrl: bed['image_url'],
          plantedDate: DateTime.parse(bed['planted_date']),
          betelType: bed['betel_type'],
          areaSize: bed['area_size'].toDouble(),
          plantCount: bed['plant_count'],
          sameBedCount: bed['same_bed_count'],
          fertilizeHistory: fertilizeHistory,
          harvestHistory: harvestHistory,
          status: BetelBedStatus.values.firstWhere(
            (e) => e.toString() == 'BetelBedStatus.${bed['status']}',
            orElse: () => BetelBedStatus.healthy,
          ),
        );
      }).toList();
    } catch (e) {
      print('Error fetching betel beds: $e');
      rethrow;
    }
  }

  // add a new betel bed
  Future<BetelBed> addBetelBed(BetelBed bed, File imageFile) async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }
      // first upload the image
      final fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      final filePath = 'betel_beds/$fileName';

      await supabase.client.storage.from('images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      // get the public URL for the uploaded image
      final imageUrl =
          supabase.client.storage.from('images').getPublicUrl(filePath);

      // insert the bed record
      final bedData = {
        'user_id': user.id,
        'name': bed.name,
        'address': bed.address,
        'district': bed.district,
        'image_url': imageUrl,
        'planted_date': bed.plantedDate.toIso8601String(),
        'betel_type': bed.betelType,
        'area_size': bed.areaSize,
        'plant_count': bed.plantCount,
        'same_bed_count': bed.sameBedCount,
        'status': bed.status.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase.client
          .from('betel_beds')
          .insert(bedData)
          .select()
          .single();

      // return the new bed with the ID from Supabase
      return BetelBed(
        id: response['id'],
        name: response['name'],
        address: response['address'],
        district: response['district'],
        imageUrl: response['image_url'],
        plantedDate: DateTime.parse(response['planted_date']),
        betelType: response['betel_type'],
        areaSize: response['area_size'].toDouble(),
        plantCount: response['plant_count'],
        sameBedCount: response['same_bed_count'],
        fertilizeHistory: [],
        harvestHistory: [],
        status: BetelBedStatus.values.firstWhere(
          (e) => e.toString() == 'BetelBedStatus.${response['status']}',
          orElse: () => BetelBedStatus.healthy,
        ),
      );
    } catch (e) {
      print('Error adding betel bed: $e');
      rethrow;
    }
  }

  // update a existing betel bed
  Future<void> updateBed(BetelBed bed) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      // prepare the update data
      final updateData = {
        'name': bed.name,
        'address': bed.address,
        'district': bed.district,
        'planted_date': bed.plantedDate.toIso8601String(),
        'betel_type': bed.betelType,
        'area_size': bed.areaSize,
        'plant_count': bed.plantCount,
        'same_bed_count': bed.sameBedCount,
      };

      // update the bed record
      await supabase.client
          .from('betel_beds')
          .update(updateData)
          .eq('id', bed.id);
    } catch (e) {
      print('Error updating betel bed: $e');
      rethrow;
    }
  }

  // update a betel bed with a new image
  Future<BetelBed> updateBedWithImage(BetelBed bed, File imageFile) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      final existingBed = await supabase.client
          .from('betel_beds')
          .select('image_url')
          .eq('id', bed.id)
          .single();

      final existingImageUrl = existingBed['image_url'] as String;

      // delete the old image if it exists
      if (existingImageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(existingImageUrl);
          final path = uri.path;
          final filePath = path.startsWith('/') ? path.substring(1) : path;

          if (filePath.startsWith('storage/')) {
            final storagePath = filePath.replaceFirst('storage/', '');
            final parts = storagePath.split('/');
            if (parts.length >= 2) {
              final bucket = parts[0];
              final fileKey = parts.sublist(1).join('/');
              await supabase.client.storage.from(bucket).remove([fileKey]);
            }
          }
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      // upload the new image
      final fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      final filePath = 'betel_beds/$fileName';

      await supabase.client.storage.from('images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // get the public URL for the uploaded image
      final newImageUrl =
          supabase.client.storage.from('images').getPublicUrl(filePath);

      // Prepare the update data
      final updateData = {
        'name': bed.name,
        'address': bed.address,
        'district': bed.district,
        'image_url': newImageUrl,
        'planted_date': bed.plantedDate.toIso8601String(),
        'betel_type': bed.betelType,
        'area_size': bed.areaSize,
        'plant_count': bed.plantCount,
        'same_bed_count': bed.sameBedCount,
      };

      // update bed record
      final response = await supabase.client
          .from('betel_beds')
          .update(updateData)
          .eq('id', bed.id)
          .select()
          .single();

      // return updated bed
      return BetelBed(
        id: response['id'],
        name: response['name'],
        address: response['address'],
        district: response['district'],
        imageUrl: response['image_url'],
        plantedDate: DateTime.parse(response['planted_date']),
        betelType: response['betel_type'],
        areaSize: response['area_size'].toDouble(),
        plantCount: response['plant_count'],
        sameBedCount: response['same_bed_count'],
        fertilizeHistory: bed.fertilizeHistory,
        harvestHistory: bed.harvestHistory,
        status: BetelBedStatus.values.firstWhere(
          (e) => e.toString() == 'BetelBedStatus.${response['status']}',
          orElse: () => bed.status,
        ),
      );
    } catch (e) {
      print('Error updating betel bed with image: $e');
      rethrow;
    }
  }

  // add fertilize record to a bed
  Future<FertilizeRecord> addFertilizeRecord(
      String bedId, FertilizeRecord record) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      final recordData = {
        'betel_bed_id': bedId,
        'date': record.date.toIso8601String(),
        'fertilizer_type': record.fertilizerType,
        'quantity': record.quantity,
        'notes': record.notes,
      };

      final response = await supabase.client
          .from('fertilize_history')
          .insert(recordData)
          .select()
          .single();

      // Update the bed status
      await supabase.client.from('betel_beds').update({
        'status': BetelBedStatus.recentlyFertilized.toString().split('.').last
      }).eq('id', bedId);

      return FertilizeRecord(
        id: response['id'],
        date: DateTime.parse(response['date']),
        fertilizerType: response['fertilizer_type'],
        quantity: response['quantity'].toDouble(),
        notes: response['notes'] ?? '',
      );
    } catch (e) {
      print('Error adding fertilize record: $e');
      rethrow;
    }
  }

  // add harvest record to a bed
  Future<HarvestRecord> addHarvestRecord(
      String bedId, HarvestRecord record) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      final recordData = {
        'betel_bed_id': bedId,
        'date': record.date.toIso8601String(),
        'leaves_count': record.leavesCount,
        'weight': record.weight,
        'revenue_earned': record.revenueEarned,
        'quality': record.quality,
        'notes': record.notes,
      };

      final response = await supabase.client
          .from('harvest_history')
          .insert(recordData)
          .select()
          .single();

      // Update the bed status
      await supabase.client.from('betel_beds').update({
        'status': BetelBedStatus.recentlyHarvested.toString().split('.').last
      }).eq('id', bedId);

      return HarvestRecord(
        id: response['id'],
        date: DateTime.parse(response['date']),
        leavesCount: response['leaves_count'],
        weight: response['weight'].toDouble(),
        revenueEarned: response['revenue_earned'].toDouble(),
        quality: response['quality'],
        notes: response['notes'] ?? '',
      );
    } catch (e) {
      print('Error adding harvest record: $e');
      rethrow;
    }
  }

  // update bed status
  Future<void> updateBedStatus(String bedId, BetelBedStatus status) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      await supabase.client.from('betel_beds').update(
          {'status': status.toString().split('.').last}).eq('id', bedId);
    } catch (e) {
      print('Error updating bed status: $e');
      rethrow;
    }
  }

// delete a betel bed and all its related records
  Future<void> deleteBed(String bedId) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      final bed = await supabase.client
          .from('betel_beds')
          .select('image_url')
          .eq('id', bedId)
          .single();

      final imageUrl = bed['image_url'] as String;
      await supabase.client.from('betel_beds').delete().eq('id', bedId);

      if (imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final path = uri.path;
          final filePath = path.startsWith('/') ? path.substring(1) : path;

          if (filePath.startsWith('storage/')) {
            final storagePath = filePath.replaceFirst('storage/', '');
            final parts = storagePath.split('/');
            if (parts.length >= 2) {
              final bucket = parts[0];
              final fileKey = parts.sublist(1).join('/');
              await supabase.client.storage.from(bucket).remove([fileKey]);
            }
          }
        } catch (imageError) {
          print('Error deleting image file: $imageError');
        }
      }

      return;
    } catch (e) {
      print('Error deleting betel bed: $e');
      rethrow;
    }
  }
}
