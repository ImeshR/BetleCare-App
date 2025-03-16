import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:betlecare/services/popup_notification_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  // Keep track of deleted notification keys
  Set<String> _deletedNotificationKeys = {};
  
  // Supabase real-time subscription
  RealtimeChannel? _notificationSubscription;
  
  // Callback to notify provider of changes
  Function? _onNotificationsChanged;

  // Popup notification service
  final PopupNotificationService _popupService = PopupNotificationService();
  
  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize popup notifications
    await _popupService.initialize();
    
    // Start real-time subscription with a delay to ensure auth is ready
    await Future.delayed(const Duration(seconds: 2));
    await _setupRealtimeSubscription();
  }
  
  // Setup real-time subscription to notifications
  Future<void> _setupRealtimeSubscription() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      debugPrint('Cannot setup real-time subscription: User not authenticated');
      return;
    }
    
    // Close existing subscription if any
    await _unsubscribeFromNotifications();
    
    try {
      debugPrint('Setting up real-time subscription for user ${user.id}...');
      
      // Create channel with a unique name to avoid conflicts
      final channelName = 'notifications-${user.id.substring(0, 8)}';
      
      _notificationSubscription = supabase.client
        .channel(channelName)
        .onPostgresChanges(
          schema: 'public',
          table: 'notifications',
          event: PostgresChangeEvent.insert,
          callback: (payload) {
            debugPrint('⚡ INSERT notification event received');
            _handleNotificationPayload(payload.newRecord as Map<String, dynamic>);
            _triggerNotificationRefresh();
          })
        .onPostgresChanges(
          schema: 'public',
          table: 'notifications',
          event: PostgresChangeEvent.update,
          callback: (payload) {
            debugPrint('⚡ UPDATE notification event received');
            
            // Check if status changed to active
            final Map<String, dynamic> newRecord = payload.newRecord as Map<String, dynamic>;
            final Map<String, dynamic> oldRecord = payload.oldRecord as Map<String, dynamic>;
            
            if (newRecord['status'] == 'active' && oldRecord['status'] == 'deleted') {
              debugPrint('⚡ Status changed from deleted to active - showing popup notification');
              
              // Create a BetelNotification object to show as popup
              final notification = BetelNotification.fromJson(newRecord);
              
              // Only show popup if the notification is not read
              if (!notification.isRead) {
                _popupService.showNotification(notification);
              }
            }
            
            _triggerNotificationRefresh();
          })
        .onPostgresChanges(
          schema: 'public',
          table: 'notifications',
          event: PostgresChangeEvent.delete,
          callback: (payload) {
            debugPrint('⚡ DELETE notification event received');
            _triggerNotificationRefresh();
          });
    
      _notificationSubscription = _notificationSubscription!.subscribe((status, error) {
        if (status == 'SUBSCRIBED') {
          debugPrint('✅ Successfully subscribed to notification changes');
        } else if (status == 'CLOSED') {
          debugPrint('❌ Subscription to notification changes closed');
        } else if (status == 'CHANNEL_ERROR') {
          debugPrint('❌ Error in notification subscription: $error');
        }
      });
    } catch (e) {
      debugPrint('❌ Error setting up real-time subscription: $e');
    }
  }
  
  void _handleNotificationPayload(Map<String, dynamic> notificationData) async {
    try {
      // Parse the notification data
      final notification = BetelNotification.fromJson(notificationData);
      
      // Skip if the notification is already read
      if (notification.isRead) return;
      
      // Show popup notification
      await _popupService.showNotification(notification);
    } catch (e) {
      debugPrint('Error handling notification payload: $e');
    }
  }
  
  // Trigger a notification refresh
  void _triggerNotificationRefresh() {
    if (_onNotificationsChanged != null) {
      debugPrint('🔄 Triggering notification refresh callback');
      _onNotificationsChanged!();
    } else {
      debugPrint('⚠️ No notification callback registered');
    }
  }
  
  // Unsubscribe from notifications
  Future<void> _unsubscribeFromNotifications() async {
    if (_notificationSubscription != null) {
      try {
        await _notificationSubscription!.unsubscribe();
        debugPrint('Unsubscribed from notification changes');
      } catch (e) {
        debugPrint('Error unsubscribing from notifications: $e');
      }
      _notificationSubscription = null;
    }
  }
  
  // Refresh the subscription (useful if connection is lost)
  Future<void> refreshSubscription() async {
    debugPrint('🔄 Refreshing notification subscription');
    await _unsubscribeFromNotifications();
    await _setupRealtimeSubscription();
  }
  
  // Register callback for notification changes
  void setNotificationCallback(Function callback) {
    debugPrint('Setting notification callback');
    _onNotificationsChanged = callback;
  }
  
  // Remove callback
  void removeNotificationCallback() {
    _onNotificationsChanged = null;
  }
  
  // Generate a unique key for a notification to avoid duplicates
  String _generateUniqueKey(String title, String message, String type, String? bedId) {
    final keyData = '$title-$message-$type-$bedId';
    final bytes = utf8.encode(keyData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Get all notifications for current user
  Future<List<BetelNotification>> getNotifications() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      debugPrint('🔍 Fetching notifications for user: ${user.id}');
      
      final data = await supabase.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .neq('status', 'deleted')  // Filter out deleted notifications
        .order('created_at', ascending: false);
      
      debugPrint('📊 Found ${data.length} notifications');
      
      return data.map<BetelNotification>((json) => 
        BetelNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      rethrow;
    }
  }
  
  // Get unread notification count
  Future<int> getUnreadCount() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      return 0;
    }
    
    try {
      debugPrint('🔍 Fetching unread notification count for user: ${user.id}');
      
      final data = await supabase.client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false)
        .neq('status', 'deleted');  // Filter out deleted notifications
      
      final count = data.length;
      debugPrint('📊 Unread notification count: $count');
      
      return count;
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return 0;
    }
  }
  
  // Check if notification with similar content already exists to avoid duplicates
  Future<bool> _notificationExists(String uniqueKey) async {
    if (_deletedNotificationKeys.contains(uniqueKey)) {
      return true; // Consider deleted notifications as existing
    }
    
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      return false;
    }
    
    final data = await supabase.client
      .from('notifications')
      .select('id')
      .eq('user_id', user.id)
      .eq('unique_key', uniqueKey)
      .limit(1);
    
    return data.isNotEmpty;
  }
  
  // Create a new notification
  Future<BetelNotification?> createNotification({
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
    
    // Generate a unique key for this notification to check for duplicates
    final uniqueKey = _generateUniqueKey(title, message, type.toString(), bedId);
    
    // Don't create duplicate notifications
    final exists = await _notificationExists(uniqueKey);
    if (exists) {
      return null; // Skip creating this notification
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
      'status': 'active',
      'unique_key': uniqueKey,
    };
    
    try {
      debugPrint('📝 Creating new notification: $title');
      
      final response = await supabase.client
        .from('notifications')
        .insert(notification)
        .select()
        .single();
      
      debugPrint('✅ Notification created with ID: ${response['id']}');
      
      // Create a BetelNotification object
      final betelNotification = BetelNotification.fromJson(response);
      
      // Show popup notification
      await _popupService.showNotification(betelNotification);
      
      return betelNotification;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      rethrow;
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final supabase = await SupabaseClientManager.instance;
    
    try {
      debugPrint('📝 Marking notification as read: $notificationId');
      
      await supabase.client
        .from('notifications')
        .update({
          'is_read': true,
          'status': 'read'
        })
        .eq('id', notificationId);
      
      debugPrint('✅ Notification marked as read');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      rethrow;
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      debugPrint('📝 Marking all notifications as read for user: ${user.id}');
      
      await supabase.client
        .from('notifications')
        .update({
          'is_read': true,
          'status': 'read'
        })
        .eq('user_id', user.id)
        .eq('status', 'active');
      
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }
  
  // Soft delete a notification
  Future<void> deleteNotification(String notificationId, String uniqueKey) async {
    // Remember this notification key to avoid recreating it
    if (uniqueKey.isNotEmpty) {
      _deletedNotificationKeys.add(uniqueKey);
    }
    
    final supabase = await SupabaseClientManager.instance;
    
    try {
      debugPrint('📝 Soft deleting notification: $notificationId');
      
      await supabase.client
        .from('notifications')
        .update({'status': 'deleted'})
        .eq('id', notificationId);
      
      debugPrint('✅ Notification soft deleted');
    } catch (e) {
      debugPrint('❌ Error soft deleting notification: $e');
      rethrow;
    }
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
  
  // Check for reactivated notifications (that have changed from deleted to active)
  Future<void> checkForReactivatedNotifications() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) return;
    
    try {
      // Get active unread notifications
      final data = await supabase.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active')
        .eq('is_read', false);
      
      if (data.isNotEmpty) {
        debugPrint('Found ${data.length} active unread notifications to check');
        
        // Show popup for each unread notification
        for (final notificationData in data) {
          final notification = BetelNotification.fromJson(notificationData);
          await _popupService.showNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('Error checking for reactivated notifications: $e');
    }
  }
  
  // Clean up resources
  void dispose() {
    _unsubscribeFromNotifications();
    _onNotificationsChanged = null;
    _popupService.dispose();
  }
}