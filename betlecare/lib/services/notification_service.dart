import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:betlecare/services/weather_services2.dart';
import 'package:betlecare/main.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:betlecare/services/popup_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  // Demo mode setting
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  
  // Keep track of deleted notification keys
  Set<String> _deletedNotificationKeys = {};
  
  // Supabase real-time subscription
  RealtimeChannel? _notificationSubscription;
  
  // Callback to notify provider of changes
  Function? _onNotificationsChanged;

  // Popup notification service
  final PopupNotificationService _popupService = PopupNotificationService();
  
  // Toggle demo mode
  Future<void> setDemoMode(bool value) async {
    _demoMode = value;
    // Store in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_demo_mode', value);
  }
  
  // Initialize - check for demo mode and load deleted notifications
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _demoMode = prefs.getBool('notification_demo_mode') ?? false;
    
    // Load deleted notification keys
    final deletedKeysJson = prefs.getStringList('deleted_notification_keys') ?? [];
    _deletedNotificationKeys = Set<String>.from(deletedKeysJson);
    
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
          debugPrint('⚡ INSERT notification event received: ${payload.newRecord}');
          _handleNotificationPayload(payload.newRecord as Map<String, dynamic>);
          _triggerNotificationRefresh();
        })
      .onPostgresChanges(
        schema: 'public',
        table: 'notifications',
        event: PostgresChangeEvent.update,
        callback: (payload) {
          debugPrint('⚡ UPDATE notification event received:');
          debugPrint('  - Old: ${payload.oldRecord}');
          debugPrint('  - New: ${payload.newRecord}');
          
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
              
              // Store this notification ID to avoid showing it again later
              _storeShownNotificationId(notification.id);
            }
            
            _triggerNotificationRefresh();
          } else if (newRecord['is_read'] != oldRecord['is_read']) {
            debugPrint('⚡ Read status changed - refreshing notifications');
            _triggerNotificationRefresh();
          } else {
            debugPrint('⚡ Other update detected - refreshing notifications');
            _triggerNotificationRefresh();
          }
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
      } else {
        debugPrint('⚠️ Notification subscription status: $status');
      }
    });
  } catch (e) {
    debugPrint('❌ Error setting up real-time subscription: $e');
  }
}

  
 // Helper method to store notification IDs that we've shown popups for
Future<void> _storeShownNotificationId(String notificationId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final shownIds = prefs.getStringList('shown_notification_popups') ?? [];
    
    if (!shownIds.contains(notificationId)) {
      shownIds.add(notificationId);
      await prefs.setStringList('shown_notification_popups', shownIds);
    }
  } catch (e) {
    debugPrint('Error storing shown notification ID: $e');
  }
} 
  
  
void _handleNotificationPayload(Map<String, dynamic> notificationData) async {
  try {
    // Parse the notification data
    final notification = BetelNotification.fromJson(notificationData);
    
    // Skip if the notification is already read
    if (notification.isRead) return;
    
    // Check if we've already shown a popup for this notification
    final prefs = await SharedPreferences.getInstance();
    final shownIds = prefs.getStringList('shown_notification_popups') ?? [];
    
    if (!shownIds.contains(notification.id)) {
      // Show popup notification
      await _popupService.showNotification(notification);
      
      // Add to shown list
      shownIds.add(notification.id);
      await prefs.setStringList('shown_notification_popups', shownIds);
    }
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
  
  // Save deleted notification keys
  Future<void> _saveDeletedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('deleted_notification_keys', _deletedNotificationKeys.toList());
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
    
    // For demo mode, return demo notifications
    if (_demoMode) {
      return _getDemoNotifications();
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
    // For demo mode, use demo notifications
    if (_demoMode) {
      final demoNotifications = _getDemoNotifications();
      return demoNotifications.where((notification) => !notification.isRead).length;
    }
    
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;
    
    if (user == null) {
      return 0;
    }
    
    try {
      debugPrint('🔍 Fetching unread notification count for user: ${user.id}');
      
      // For Supabase Flutter
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
    
    if (_demoMode) {
      // In demo mode, create a fake notification and show popup
      final notification = BetelNotification(
        id: const Uuid().v4(),
        userId: user.id,
        bedId: bedId,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        metadata: metadata,
        uniqueKey: uniqueKey,
      );
      
      // Show popup notification
      await _popupService.showNotification(notification);
      
      return notification;
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
    if (_demoMode) return; // Do nothing in demo mode
    
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
    if (_demoMode) return; // Do nothing in demo mode
    
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
    if (_demoMode) return; // Do nothing in demo mode
    
    // Remember this notification key to avoid recreating it
    if (uniqueKey.isNotEmpty) {
      _deletedNotificationKeys.add(uniqueKey);
      await _saveDeletedKeys();
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
      
      // Get IDs of notifications we've already shown popups for
      final prefs = await SharedPreferences.getInstance();
      final shownNotificationIds = prefs.getStringList('shown_notification_popups') ?? [];
      
      // Show popup for each notification that hasn't been shown before
      for (final notificationData in data) {
        final notification = BetelNotification.fromJson(notificationData);
        
        // Only show popup if we haven't shown it before
        if (!shownNotificationIds.contains(notification.id)) {
          debugPrint('Showing popup for notification: ${notification.id}');
          await _popupService.showNotification(notification);
          
          // Add to shown list
          shownNotificationIds.add(notification.id);
        }
      }
      
      // Save updated list of shown notification IDs
      await prefs.setStringList('shown_notification_popups', shownNotificationIds);
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
  
  // DEMO MODE METHODS
  
  // Generate demo notifications for preview/presentation
  List<BetelNotification> _getDemoNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
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
        uniqueKey: 'demo-1',
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
        uniqueKey: 'demo-2',
      ),
      BetelNotification(
        id: '3',
        userId: user.id,
        title: 'අධික උෂ්ණත්ව අනතුරු ඇඟවීම',
        message: 'ඔබගේ කුරුණෑගල වගාව සඳහා සතියේ ඉතිරි දිනවල අධික උෂ්ණත්වයක් (36.5°C) අපේක්ෂා කෙරේ. ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි අවධානය යොමු කරන්න.',
        createdAt: twoDaysAgo,
        type: NotificationType.weather,
        metadata: {'weather_type': 'high_temperature', 'temperature': 36.5},
        uniqueKey: 'demo-3',
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
        uniqueKey: 'demo-4',
      ),
    ];
  }
  
  // Generate a demo notification immediately
  Future<void> createDemoNotification(
    BetelBed bed, 
    NotificationType type, 
    {Map<String, dynamic>? metadata}
  ) async {
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