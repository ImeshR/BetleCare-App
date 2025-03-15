// notification_service.dart
import 'package:uuid/uuid.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:betlecare/services/weather_services2.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  // Demo mode setting
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  
  // Toggle demo mode
  Future<void> setDemoMode(bool value) async {
    _demoMode = value;
    // Store in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_demo_mode', value);
  }
  
  // Initialize - check for demo mode
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _demoMode = prefs.getBool('notification_demo_mode') ?? false;
  }
  
  // Get all notifications for current user
  Future<List<BetelNotification>> getNotifications() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // For demo mode, return demo notifications
    if (_demoMode) {
      return _getDemoNotifications();
    }
    
    final data = await supabase.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
    
    return data.map<BetelNotification>((json) => 
      BetelNotification.fromJson(json)).toList();
  }
  
  // Get unread notification count
  Future<int> getUnreadCount() async {
    // For demo mode, use demo notifications
    if (_demoMode) {
      final demoNotifications = await _getDemoNotifications();
      return demoNotifications.where((notification) => !notification.isRead).length;
    }
    
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      return 0;
    }
    
    // For Supabase Flutter 2.8.3
    final data = await supabase.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .eq('is_read', false);
    
    // Simply count the returned rows
    return data.length;
  }
  
  // Create a new notification
  Future<BetelNotification> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? bedId,
    Map<String, dynamic>? metadata,
  }) async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    if (_demoMode) {
      // In demo mode, just return a fake notification without saving to DB
      return BetelNotification(
        id: const Uuid().v4(),
        userId: user.id,
        bedId: bedId,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        metadata: metadata,
      );
    }
    
    final notification = {
      'user_id': user.id,
      'bed_id': bedId,
      'title': title,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
    
    final response = await supabase.client
      .from('notifications')
      .insert(notification)
      .select()
      .single();
    
    return BetelNotification.fromJson(response);
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_demoMode) return; // Do nothing in demo mode
    
    final supabase = await SupabaseClientManager.instance;
    
    await supabase.client
      .from('notifications')
      .update({'is_read': true})
      .eq('id', notificationId);
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_demoMode) return; // Do nothing in demo mode
    
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await supabase.client
      .from('notifications')
      .update({'is_read': true})
      .eq('user_id', user.id);
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (_demoMode) return; // Do nothing in demo mode
    
    final supabase = await SupabaseClientManager.instance;
    
    await supabase.client
      .from('notifications')
      .delete()
      .eq('id', notificationId);
  }
  
  // Weather alert - check forecasted rainfall/temperature and create notifications
  Future<void> checkWeatherAlerts(List<BetelBed> beds) async {
    for (final bed in beds) {
      // Check if rainfall exceeds threshold (10mm is heavy rain in Sri Lanka)
      final weatherData = await _getWeatherData(bed.district);
      
      if (weatherData == null) continue;
      
      // Check for heavy rainfall in next 7 days
      await _checkRainfallAlerts(bed, weatherData);
      
      // Check for extreme temperatures
      await _checkTemperatureAlerts(bed, weatherData);
    }
  }
  
  // Check for rainfall alerts
  Future<void> _checkRainfallAlerts(BetelBed bed, Map<String, dynamic> weatherData) async {
    final daily = weatherData['daily'];
    if (daily == null) return;
    
    final highRainfallThreshold = 10.0; // 10mm per day is considered heavy rain
    
    // Check each day in forecast
    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final rainfall = daily['precipitation_sum'][i].toDouble();
      
      // If rainfall will exceed threshold, create alert
      if (rainfall >= highRainfallThreshold) {
        final formattedDate = date.toString().substring(0, 10);
        
        await createNotification(
          title: 'අධික වැසි අනතුරු ඇඟවීම',  // Heavy rain warning
          message: '${bed.name} සඳහා ${formattedDate} දිනට අධික වැසි අපේක්ෂා කෙරේ (${rainfall.toStringAsFixed(1)}mm). ඔබගේ බුලත් වගාව ආරක්ෂා කර ගැනීමට අවශ්‍ය පියවර ගන්න.',
          type: NotificationType.weather,
          bedId: bed.id,
          metadata: {
            'rainfall': rainfall,
            'date': formattedDate,
            'district': bed.district,
            'weather_type': 'heavy_rain',
          },
        );
      }
    }
  }
  
  // Check for temperature alerts
  Future<void> _checkTemperatureAlerts(BetelBed bed, Map<String, dynamic> weatherData) async {
    final daily = weatherData['daily'];
    if (daily == null) return;
    
    final highTempThreshold = 34.0; // 34°C can be harmful for betel plants
    
    // Check each day in forecast
    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final maxTemp = daily['temperature_2m_max'][i].toDouble();
      
      // If temperature will exceed threshold, create alert
      if (maxTemp >= highTempThreshold) {
        final formattedDate = date.toString().substring(0, 10);
        
        await createNotification(
          title: 'අධික උෂ්ණත්ව අනතුරු ඇඟවීම',  // High temperature warning
          message: '${bed.name} සඳහා ${formattedDate} දිනට අධික උෂ්ණත්වයක් අපේක්ෂා කෙරේ (${maxTemp.toStringAsFixed(1)}°C). ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි අවධානය යොමු කරන්න.',
          type: NotificationType.weather,
          bedId: bed.id,
          metadata: {
            'temperature': maxTemp,
            'date': formattedDate,
            'district': bed.district,
            'weather_type': 'high_temperature',
          },
        );
      }
    }
  }
  
  // Check for harvest alerts
  Future<void> checkHarvestAlerts(List<BetelBed> beds) async {
    for (final bed in beds) {
      // First harvest is typically around 105 days (3.5 months) after planting
      final firstHarvestDays = 105;
      final daysTillFirstHarvest = bed.plantedDate
        .add(Duration(days: firstHarvestDays))
        .difference(DateTime.now())
        .inDays;
      
      // If approaching first harvest (7 days before)
      if (daysTillFirstHarvest > 0 && daysTillFirstHarvest <= 7) {
        await createNotification(
          title: 'අස්වනු කාලය ළඟයි',  // Harvest time approaching
          message: '${bed.name} සඳහා පළමු අස්වැන්න නෙලීමට දින ${daysTillFirstHarvest} ක් පමණ ඉතිරිව ඇත. අස්වනු නෙලීමට සූදානම් වන්න.',
          type: NotificationType.harvest,
          bedId: bed.id,
          metadata: {
            'days_till_harvest': daysTillFirstHarvest,
            'harvest_type': 'first',
          },
        );
      }
      
      // Subsequent harvests happen approximately every 30 days
      if (bed.harvestHistory.isNotEmpty) {
        final lastHarvestDate = bed.harvestHistory.last.date;
        final daysSinceLastHarvest = DateTime.now().difference(lastHarvestDate).inDays;
        
        // Regular harvest cycle is typically 30 days
        const harvestCycle = 30;
        
        // If it's been more than 30 days since last harvest, send a reminder
        if (daysSinceLastHarvest >= harvestCycle) {
          await createNotification(
            title: 'නව අස්වනු කාලය',  // New harvest time
            message: '${bed.name} සඳහා අස්වනු නෙලීමට කාලය පැමිණ ඇත. අවසන් අස්වැන්න සිට දින ${daysSinceLastHarvest}ක් ගතවී ඇත.',
            type: NotificationType.harvest,
            bedId: bed.id,
            metadata: {
              'days_since_last_harvest': daysSinceLastHarvest,
              'harvest_type': 'regular',
            },
          );
        }
      }
    }
  }
  
  // Get weather data for a district
  Future<Map<String, dynamic>?> _getWeatherData(String district) async {
    final weatherService = WeatherService();
    return await weatherService.fetchWeatherData(district);
  }
  
  // DEMO MODE METHODS
  
  // Generate demo notifications for preview/presentation
 List<BetelNotification> _getDemoNotifications() {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final twoDaysAgo = now.subtract(const Duration(days: 2));
    
    return [
      BetelNotification(
        id: '1',
        userId: user.id,
        title: 'අධික වැසි අනතුරු ඇඟවීම',
        message: 'ඔබගේ කොළඹ වගාව සඳහා හෙට දිනට අධික වැසි (15.2mm) අපේක්ෂා කෙරේ. ඔබගේ බුලත් වගාව ආරක්ෂා කර ගැනීමට අවශ්‍ය පියවර ගන්න.',
        createdAt: now,
        type: NotificationType.weather,
        metadata: {'weather_type': 'heavy_rain', 'rainfall': 15.2},
      ),
      BetelNotification(
        id: '2',
        userId: user.id,
        title: 'අස්වනු කාලය ළඟයි',
        message: 'ඔබගේ පුත්තලම වගාව සඳහා පළමු අස්වැන්න නෙලීමට දින 3 ක් පමණ ඉතිරිව ඇත. අස්වනු නෙලීමට සූදානම් වන්න.',
        createdAt: yesterday,
        type: NotificationType.harvest,
        isRead: true,
        metadata: {'days_till_harvest': 3, 'harvest_type': 'first'},
      ),
      BetelNotification(
        id: '3',
        userId: user.id,
        title: 'අධික උෂ්ණත්ව අනතුරු ඇඟවීම',
        message: 'ඔබගේ කුරුණෑගල වගාව සඳහා සතියේ ඉතිරි දිනවල අධික උෂ්ණත්වයක් (36.5°C) අපේක්ෂා කෙරේ. ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි අවධානය යොමු කරන්න.',
        createdAt: twoDaysAgo,
        type: NotificationType.weather,
        metadata: {'weather_type': 'high_temperature', 'temperature': 36.5},
      ),
      BetelNotification(
        id: '4',
        userId: user.id,
        title: 'පොහොර යෙදීමේ කාලය',
        message: 'ඔබගේ අනමඩුව වගාව සඳහා පොහොර යෙදීමට කාලය පැමිණ ඇත. අවසන් පොහොර යෙදීමේ සිට දින 30කට වඩා ගතවී ඇත.',
        createdAt: twoDaysAgo,
        type: NotificationType.fertilize,
        isRead: true,
        metadata: {'days_since_last_fertilize': 30},
      ),
    ];
  }
  
  // Access to Supabase for demo notifications
  SupabaseClient get supabase => Supabase.instance.client;
  
  // Generate a demo notification immediately
  Future<void> createDemoNotification(
    BetelBed bed, 
    NotificationType type, 
    {Map<String, dynamic>? metadata}
  ) async {
    if (!_demoMode) {
      // Set demo mode true temporarily
      bool originalMode = _demoMode;
      _demoMode = true;
      
      switch (type) {
        case NotificationType.weather:
          if (metadata?['weather_type'] == 'heavy_rain') {
            final rainfall = metadata?['rainfall'] ?? 15.2;
            await createNotification(
              title: 'අධික වැසි අනතුරු ඇඟවීම (Demo)',
              message: '${bed.name} සඳහා හෙට දිනට අධික වැසි (${rainfall}mm) අපේක්ෂා කෙරේ. ඔබගේ බුලත් වගාව ආරක්ෂා කර ගැනීමට අවශ්‍ය පියවර ගන්න.',
              type: NotificationType.weather,
              bedId: bed.id,
              metadata: {'weather_type': 'heavy_rain', 'rainfall': rainfall},
            );
          } else if (metadata?['weather_type'] == 'high_temperature') {
            final temp = metadata?['temperature'] ?? 36.5;
            await createNotification(
              title: 'අධික උෂ්ණත්ව අනතුරු ඇඟවීම (Demo)',
              message: '${bed.name} සඳහා සතියේ ඉතිරි දිනවල අධික උෂ්ණත්වයක් (${temp}°C) අපේක්ෂා කෙරේ. ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි අවධානය යොමු කරන්න.',
              type: NotificationType.weather,
              bedId: bed.id,
              metadata: {'weather_type': 'high_temperature', 'temperature': temp},
            );
          }
          break;
          
        case NotificationType.harvest:
          await createNotification(
            title: 'අස්වනු කාලය ළඟයි (Demo)',
            message: '${bed.name} සඳහා පළමු අස්වැන්න නෙලීමට දින 3 ක් පමණ ඉතිරිව ඇත. අස්වනු නෙලීමට සූදානම් වන්න.',
            type: NotificationType.harvest,
            bedId: bed.id,
            metadata: {'days_till_harvest': 3, 'harvest_type': 'first'},
          );
          break;
          
        case NotificationType.fertilize:
          await createNotification(
            title: 'පොහොර යෙදීමේ කාලය (Demo)',
            message: '${bed.name} සඳහා පොහොර යෙදීමට කාලය පැමිණ ඇත. අවසන් පොහොර යෙදීමේ සිට දින 30කට වඩා ගතවී ඇත.',
            type: NotificationType.fertilize,
            bedId: bed.id,
            metadata: {'days_since_last_fertilize': 30},
          );
          break;
          
        case NotificationType.system:
          await createNotification(
            title: 'පද්ධති දැනුම්දීම (Demo)',
            message: 'මෙය පද්ධති දැනුම්දීමක් සඳහා උදාහරණයකි.',
            type: NotificationType.system,
            bedId: bed.id,
          );
          break;
      }
      
      // Restore original mode
      _demoMode = originalMode;
    }
  }
}