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


  Set<String> _deletedNotificationKeys = {};

 
  RealtimeChannel? _notificationSubscription;

  // callback to notify provider of changes
  Function? _onNotificationsChanged;

  // popup notification service
  final PopupNotificationService _popupService = PopupNotificationService();

  // user notification preferences
  bool _notificationsEnabled = true;
  bool _weatherNotificationsEnabled = true;
  bool _harvestNotificationsEnabled = true;
  bool _fertilizeNotificationsEnabled = true;
  bool _diseaseNotificationsEnabled = true;

  // initialize the notification service
  Future<void> initialize() async {
    
    await _popupService.initialize();
    await _loadUserNotificationPreferences();
    await Future.delayed(const Duration(seconds: 2));
    await _setupRealtimeSubscription();
  }

  // load user notification preferences from db
  Future<void> _loadUserNotificationPreferences() async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user == null) {
        debugPrint(
            'Cannot load notification preferences: User not authenticated');
        return;
      }

      final userSettings = await supabase.client
          .from('user_settings')
          .select()
          .eq('userid', user.id)
          .maybeSingle();

      if (userSettings != null) {
        _notificationsEnabled = userSettings['notification_enable'] ?? true;

        final notificationPrefs = await supabase.client
            .from('notification_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (notificationPrefs != null) {
          _weatherNotificationsEnabled =
              notificationPrefs['weather_notifications'] ?? true;
          _harvestNotificationsEnabled =
              notificationPrefs['harvest_notifications'] ?? true;
          _fertilizeNotificationsEnabled =
              notificationPrefs['fertilize_notifications'] ?? true;
          _diseaseNotificationsEnabled =
              notificationPrefs['disease_notifications'] ?? true;
        } else {
          
          await _createDefaultNotificationPreferences(user.id);
        }
      } else {
        debugPrint('User settings not found for user ${user.id}');
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  // create default notification preferences
  Future<void> _createDefaultNotificationPreferences(String userId) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      await supabase.client.from('notification_preferences').insert({
        'user_id': userId,
        'weather_notifications': true,
        'harvest_notifications': true,
        'fertilize_notifications': true,
        'disease_notifications': true,
      });

      debugPrint('Created default notification preferences for user $userId');
    } catch (e) {
      debugPrint('Error creating default notification preferences: $e');
    }
  }

  // setup real-time subscription to notifications
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
      final channelName = 'notifications-${user.id.substring(0, 8)}';

      _notificationSubscription = supabase.client
          .channel(channelName)
          .onPostgresChanges(
              schema: 'public',
              table: 'notifications',
              event: PostgresChangeEvent.insert,
              callback: (payload) {
                debugPrint('⚡ INSERT notification event received');
                _handleNotificationPayload(
                    payload.newRecord as Map<String, dynamic>);
                _triggerNotificationRefresh();
              })
          .onPostgresChanges(
              schema: 'public',
              table: 'notifications',
              event: PostgresChangeEvent.update,
              callback: (payload) {
                debugPrint('⚡ UPDATE notification event received');

                final Map<String, dynamic> newRecord =
                    payload.newRecord as Map<String, dynamic>;
                final Map<String, dynamic> oldRecord =
                    payload.oldRecord as Map<String, dynamic>;

                if (newRecord['status'] == 'active' &&
                    oldRecord['status'] == 'deleted') {
                  debugPrint(
                      '⚡ Status changed from deleted to active - showing popup notification');

                  final notification = BetelNotification.fromJson(newRecord);
                  if (!notification.isRead &&
                      _notificationsEnabled &&
                      _isNotificationTypeEnabled(notification.type)) {
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

      _notificationSubscription =
          _notificationSubscription!.subscribe((status, error) {
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

      final notification = BetelNotification.fromJson(notificationData);
      if (notification.isRead || notification.popupDisplayed) return;
      if (_notificationsEnabled &&
          _isNotificationTypeEnabled(notification.type)) {
        await _popupService.showNotification(notification);
        await _markPopupDisplayed(notification.id);
      }
    } catch (e) {
      debugPrint('Error handling notification payload: $e');
    }
  }

//  method to mark popup as displayed
  Future<void> _markPopupDisplayed(String notificationId) async {
    try {
      final supabase = await SupabaseClientManager.instance;

      await supabase.client
          .from('notifications')
          .update({'popup_displayed': true}).eq('id', notificationId);

      debugPrint(
          '✅ Notification popup_displayed flag updated for ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error updating popup_displayed flag: $e');
    }
  }

  bool _isNotificationTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.weather:
        return _weatherNotificationsEnabled;
      case NotificationType.harvest:
        return _harvestNotificationsEnabled;
      case NotificationType.fertilize:
        return _fertilizeNotificationsEnabled;
      case NotificationType.system:
        return true; 
      default:
        return true;
    }
  }

  void _triggerNotificationRefresh() {
    if (_onNotificationsChanged != null) {
      debugPrint('🔄 Triggering notification refresh callback');
      _onNotificationsChanged!();
    } else {
      debugPrint('⚠️ No notification callback registered');
    }
  }

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

  Future<void> refreshSubscription() async {
    debugPrint('🔄 Refreshing notification subscription');
    await _unsubscribeFromNotifications();
    await _setupRealtimeSubscription();
  }

  //  callback for notification changes
  void setNotificationCallback(Function callback) {
    debugPrint('Setting notification callback');
    _onNotificationsChanged = callback;
  }

  // remove callback
  void removeNotificationCallback() {
    _onNotificationsChanged = null;
  }

  // unique key for a notification to stop duplicates
  String _generateUniqueKey(
      String title, String message, String type, String? bedId) {
    final keyData = '$title-$message-$type-$bedId';
    final bytes = utf8.encode(keyData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get all notifications
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
          .neq('status', 'deleted') 
          .order('created_at', ascending: false);

      debugPrint('📊 Found ${data.length} notifications');

      return data
          .map<BetelNotification>((json) => BetelNotification.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  // get unread notification count
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
          .neq('status', 'deleted'); 

      final count = data.length;
      debugPrint('📊 Unread notification count: $count');

      return count;
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  // check if notification wi similar content already exists to stop duplicates
  Future<bool> _notificationExists(String uniqueKey) async {
    if (_deletedNotificationKeys.contains(uniqueKey)) {
      return true; 
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

  // create a new notification
  Future<BetelNotification?> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? bedId,
    Map<String, dynamic>? metadata,
  }) async {
    
    if (!_notificationsEnabled) {
      debugPrint('Notifications disabled, skipping creation entirely');
      return null;
    }

    if (!_isNotificationTypeEnabled(type)) {
      debugPrint('Notifications disabled for type $type, skipping creation');
      return null;
    }

    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    //unique key for this notification to check for duplicates
    final uniqueKey =
        _generateUniqueKey(title, message, type.toString(), bedId);

    
    final exists = await _notificationExists(uniqueKey);
    if (exists) {
      return null; 
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
      final betelNotification = BetelNotification.fromJson(response);
      await _popupService.showNotification(betelNotification);

      return betelNotification;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      rethrow;
    }
  }

  // mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final supabase = await SupabaseClientManager.instance;

    try {
      debugPrint('📝 Marking notification as read: $notificationId');

      await supabase.client
          .from('notifications')
          .update({'is_read': true, 'status': 'read'}).eq('id', notificationId);

      debugPrint('✅ Notification marked as read');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  // mark all notifications as read
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
          .update({'is_read': true, 'status': 'read'})
          .eq('user_id', user.id)
          .eq('status', 'active');

      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Soft delete a notification
  Future<void> deleteNotification(
      String notificationId, String uniqueKey) async {
 
    if (uniqueKey.isNotEmpty) {
      _deletedNotificationKeys.add(uniqueKey);
    }

    final supabase = await SupabaseClientManager.instance;

    try {
      debugPrint('📝 Soft deleting notification: $notificationId');

      await supabase.client
          .from('notifications')
          .update({'status': 'deleted'}).eq('id', notificationId);

      debugPrint('✅ Notification soft deleted');
    } catch (e) {
      debugPrint('❌ Error soft deleting notification: $e');
      rethrow;
    }
  }

  // get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {

      final userSettings = await supabase.client
          .from('user_settings')
          .select('notification_enable')
          .eq('userid', user.id)
          .single();

      _notificationsEnabled = userSettings['notification_enable'] ?? true;

      final notificationPrefs = await supabase.client
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (notificationPrefs != null) {
        _weatherNotificationsEnabled =
            notificationPrefs['weather_notifications'] ?? true;
        _harvestNotificationsEnabled =
            notificationPrefs['harvest_notifications'] ?? true;
        _fertilizeNotificationsEnabled =
            notificationPrefs['fertilize_notifications'] ?? true;
        _diseaseNotificationsEnabled =
            notificationPrefs['disease_notifications'] ?? true;
      } else {
        
        await _createDefaultNotificationPreferences(user.id);
      }

      return {
        'notifications_enabled': _notificationsEnabled,
        'weather_notifications': _weatherNotificationsEnabled,
        'harvest_notifications': _harvestNotificationsEnabled,
        'fertilize_notifications': _fertilizeNotificationsEnabled,
        'disease_notifications': _diseaseNotificationsEnabled,
      };
    } catch (e) {
      debugPrint('❌ Error getting notification preferences: $e');

      return {
        'notifications_enabled': true,
        'weather_notifications': true,
        'harvest_notifications': true,
        'fertilize_notifications': true,
        'disease_notifications': true,
      };
    }
  }

 
  Future<void> updateNotificationPreferences({
    bool? notificationsEnabled,
    bool? weatherNotifications,
    bool? harvestNotifications,
    bool? fertilizeNotifications,
    bool? diseaseNotifications,
  }) async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      
      if (notificationsEnabled != null) {
        await supabase.client
            .from('user_settings')
            .update({'notification_enable': notificationsEnabled}).eq(
                'userid', user.id);

        _notificationsEnabled = notificationsEnabled;

       
        if (!notificationsEnabled) {
         
          await supabase.client.from('notification_preferences').update({
            'weather_notifications': false,
            'harvest_notifications': false,
            'fertilize_notifications': false,
            'disease_notifications': false,
          }).eq('user_id', user.id);

          
          _weatherNotificationsEnabled = false;
          _harvestNotificationsEnabled = false;
          _fertilizeNotificationsEnabled = false;
          _diseaseNotificationsEnabled = false;
        }
      }

    
      if (_notificationsEnabled) {
        
        final Map<String, dynamic> prefsUpdate = {};

        if (weatherNotifications != null) {
          prefsUpdate['weather_notifications'] = weatherNotifications;
          _weatherNotificationsEnabled = weatherNotifications;
        }

        if (harvestNotifications != null) {
          prefsUpdate['harvest_notifications'] = harvestNotifications;
          _harvestNotificationsEnabled = harvestNotifications;
        }

        if (fertilizeNotifications != null) {
          prefsUpdate['fertilize_notifications'] = fertilizeNotifications;
          _fertilizeNotificationsEnabled = fertilizeNotifications;
        }

        if (diseaseNotifications != null) {
          prefsUpdate['disease_notifications'] = diseaseNotifications;
          _diseaseNotificationsEnabled = diseaseNotifications;
        }

        
        if (prefsUpdate.isNotEmpty) {
         
          final existing = await supabase.client
              .from('notification_preferences')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (existing != null) {
            
            await supabase.client
                .from('notification_preferences')
                .update(prefsUpdate)
                .eq('user_id', user.id);
          } else {
            
            prefsUpdate['user_id'] = user.id;
            await supabase.client
                .from('notification_preferences')
                .insert(prefsUpdate);
          }
        }
      }

      debugPrint('✅ Notification preferences updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating notification preferences: $e');
      rethrow;
    }
  }


// Weather alert 
Future<void> checkWeatherAlerts(List<BetelBed> beds) async {
 
  if (!_notificationsEnabled) {
    debugPrint('Notifications disabled, skipping weather checks entirely');
    return;
  }

  if (!_weatherNotificationsEnabled) {
    debugPrint('Weather notifications disabled, skipping weather checks');
    return;
  }

  Map<String, Map<String, dynamic>> weatherDataMap = {};
  for (final bed in beds) {
    final weatherData = await _getWeatherData(bed.district);
    if (weatherData != null) {
      weatherDataMap[bed.id] = weatherData;
    }
  }

  if (weatherDataMap.isEmpty) {
    debugPrint('No weather data available for any beds');
    return;
  }
  // find the bed with highest temperature and create notification for it
  await _createHighestTemperatureNotification(beds, weatherDataMap);
  // Create notifications for heavy rainfall days
  await _createHeavyRainfallNotifications(beds, weatherDataMap);
}


Future<void> _createHighestTemperatureNotification(
    List<BetelBed> beds, Map<String, Map<String, dynamic>> weatherDataMap) async {

  double highestTemp = 0;
  BetelBed? hottestBed;
  String hottestDay = '';
  
  for (final bed in beds) {
    if (!weatherDataMap.containsKey(bed.id)) continue;
    
    final weatherData = weatherDataMap[bed.id]!;
    final daily = weatherData['daily'];
    if (daily == null) continue;
    

    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final maxTemp = daily['temperature_2m_max'][i].toDouble();
      
 
      if (maxTemp > highestTemp) {
        highestTemp = maxTemp;
        hottestBed = bed;
        hottestDay = date.toString().substring(0, 10);
      }
    }
  }
  
  // create notification only if we found a high temperature
  if (hottestBed != null && highestTemp > 33.0) {
    debugPrint('Creating notification for highest temperature: $highestTemp°C for bed: ${hottestBed.name}');
    
    await createNotification(
      title: 'සතියේ අධික උෂ්ණත්ව අනතුරු ඇඟවීම', // highest temperature warning of the week
      message: '${hottestBed.name} සඳහා ${hottestDay} දිනට ඉහළම උෂ්ණත්වය අපේක්ෂා කෙරේ (${highestTemp.toStringAsFixed(1)}°C). ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි ජල සැපයුමක් පවත්වා ගන්න.',
      type: NotificationType.weather,
      bedId: hottestBed.id,
      metadata: {
        'temperature': highestTemp,
        'date': hottestDay,
        'district': hottestBed.district,
        'weather_type': 'high_temperature',
      },
    );
  }
}

Future<void> _createHeavyRainfallNotifications(
    List<BetelBed> beds, Map<String, Map<String, dynamic>> weatherDataMap) async {
  // set threshold for heavy rainfall
  final heavyRainfallThreshold = 15.0; 
  

  for (final bed in beds) {
    if (!weatherDataMap.containsKey(bed.id)) continue;
    
    final weatherData = weatherDataMap[bed.id]!;
    final daily = weatherData['daily'];
    if (daily == null) continue;
    
 
    bool notificationCreated = false;
    
    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final rainfall = daily['precipitation_sum'][i].toDouble();
      
   
      if (rainfall >= heavyRainfallThreshold && !notificationCreated) {
        final formattedDate = date.toString().substring(0, 10);
        
        debugPrint('Creating heavy rainfall notification: ${rainfall}mm for bed: ${bed.name} on $formattedDate');
        
        await createNotification(
          title: 'අධික වැසි අනතුරු ඇඟවීම',
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
        
        notificationCreated = true;  
      }
    }
  }
}


// create notifications for days with rainfall less than 15mm
Future<void> _createRainfallNotifications(
    List<BetelBed> beds, Map<String, Map<String, dynamic>> weatherDataMap) async {
  
  
  final lowRainfallThreshold = 15.0; 
  
  // Process each bed
  for (final bed in beds) {
    if (!weatherDataMap.containsKey(bed.id)) continue;
    
    final weatherData = weatherDataMap[bed.id]!;
    final daily = weatherData['daily'];
    if (daily == null) continue;
    

    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final rainfall = daily['precipitation_sum'][i].toDouble();
      

      if (rainfall < lowRainfallThreshold) {
        final formattedDate = date.toString().substring(0, 10);
        
        debugPrint('Creating low rainfall notification: ${rainfall}mm for bed: ${bed.name} on $formattedDate');
        
        await createNotification(
          title: 'අඩු වැසි අනතුරු ඇඟවීම', 
          message: '${bed.name} සඳහා ${formattedDate} දිනට අඩු වැසි අපේක්ෂා කෙරේ (${rainfall.toStringAsFixed(1)}mm). ඔබගේ බුලත් වගාවට ප්‍රමාණවත් ජලය සැපයීමට සැලසුම් කරන්න.',
          type: NotificationType.weather,
          bedId: bed.id,
          metadata: {
            'rainfall': rainfall,
            'date': formattedDate,
            'district': bed.district,
            'weather_type': 'low_rain',
          },
        );
        
        
        break;
      }
    }
  }
}

  //TODO remove  this after testing
  Future<void> _checkRainfallAlerts(
      BetelBed bed, Map<String, dynamic> weatherData) async {
    final daily = weatherData['daily'];
    if (daily == null) return;

    final highRainfallThreshold = 10.0; 

    
    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final rainfall = daily['precipitation_sum'][i].toDouble();

      
      if (rainfall >= highRainfallThreshold) {
        final formattedDate = date.toString().substring(0, 10);

        await createNotification(
          title: 'අධික වැසි අනතුරු ඇඟවීම', 
          message:
              '${bed.name} සඳහා ${formattedDate} දිනට අධික වැසි අපේක්ෂා කෙරේ (${rainfall.toStringAsFixed(1)}mm). ඔබගේ බුලත් වගාව ආරක්ෂා කර ගැනීමට අවශ්‍ය පියවර ගන්න.',
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

//TODO remove  this after testing
  // Check for temperature alerts
  Future<void> _checkTemperatureAlerts(
      BetelBed bed, Map<String, dynamic> weatherData) async {
    final daily = weatherData['daily'];
    if (daily == null) return;

    final highTempThreshold = 34.0; 

    
    for (int i = 0; i < daily['time'].length; i++) {
      final date = daily['time'][i];
      final maxTemp = daily['temperature_2m_max'][i].toDouble();

      
      if (maxTemp >= highTempThreshold) {
        final formattedDate = date.toString().substring(0, 10);

        await createNotification(
          title: 'අධික උෂ්ණත්ව අනතුරු ඇඟවීම', 
          message:
              '${bed.name} සඳහා ${formattedDate} දිනට අධික උෂ්ණත්වයක් අපේක්ෂා කෙරේ (${maxTemp.toStringAsFixed(1)}°C). ඔබගේ බුලත් පැළවලට හානි නොවන ලෙස නිසි අවධානය යොමු කරන්න.',
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
    
    if (!_notificationsEnabled || !_harvestNotificationsEnabled) {
      debugPrint('Harvest notifications disabled, skipping harvest checks');
      return;
    }

    for (final bed in beds) {
      // first harvest is typically around 105 days after planting
      final firstHarvestDays = 105;
      final daysTillFirstHarvest = bed.plantedDate
          .add(Duration(days: firstHarvestDays))
          .difference(DateTime.now())
          .inDays;

      // If approaching first harvest (7 days before)
      if (daysTillFirstHarvest > 0 && daysTillFirstHarvest <= 7) {
        await createNotification(
          title: 'අස්වනු කාලය ළඟයි', 
          message:
              '${bed.name} සඳහා පළමු අස්වැන්න නෙලීමට දින ${daysTillFirstHarvest} ක් පමණ ඉතිරිව ඇත. අස්වනු නෙලීමට සූදානම් වන්න.',
          type: NotificationType.harvest,
          bedId: bed.id,
          metadata: {
            'days_till_harvest': daysTillFirstHarvest,
            'harvest_type': 'first',
          },
        );
      }

      // harvests happen approximately every 30 days
      if (bed.harvestHistory.isNotEmpty) {
        final lastHarvestDate = bed.harvestHistory.last.date;
        final daysSinceLastHarvest =
            DateTime.now().difference(lastHarvestDate).inDays;

        const harvestCycle = 30;

        if (daysSinceLastHarvest >= harvestCycle) {
          await createNotification(
            title: 'නව අස්වනු කාලය', 
            message:
                '${bed.name} සඳහා අස්වනු නෙලීමට කාලය පැමිණ ඇත. අවසන් අස්වැන්න සිට දින ${daysSinceLastHarvest}ක් ගතවී ඇත.',
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

  // check for fertilize alerts
  Future<void> checkFertilizeAlerts(List<BetelBed> beds) async {
   
    if (!_notificationsEnabled || !_fertilizeNotificationsEnabled) {
      debugPrint('Fertilize notifications disabled, skipping fertilize checks');
      return;
    }

    for (final bed in beds) {
      if (bed.daysUntilNextFertilizing <= 3 &&
          bed.daysUntilNextFertilizing > 0) {
        await createNotification(
          title: 'පොහොර යෙදීමේ කාලය ළඟයි',
          message:
              '${bed.name} සඳහා පොහොර යෙදීම සිදු කිරීමට තව දින ${bed.daysUntilNextFertilizing}ක් පමණි.',
          type: NotificationType.fertilize,
          bedId: bed.id,
          metadata: {'days_until_fertilizing': bed.daysUntilNextFertilizing},
        );
      }
    }
  }

  // get weather data for a district
  Future<Map<String, dynamic>?> _getWeatherData(String district) async {
    final weatherService = WeatherService();
    return await weatherService.fetchWeatherData(district);
  }

  Future<void> checkForReactivatedNotifications() async {
    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;

    if (user == null) return;


    if (!_notificationsEnabled) return;

    try {
      
      final data = await supabase.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .eq('is_read', false)
          .eq('popup_displayed',
              false); 

      if (data.isNotEmpty) {
        debugPrint(
            'Found ${data.length} active unread notifications to show popups for');

    
        for (final notificationData in data) {
          final notification = BetelNotification.fromJson(notificationData);

        
          if (_isNotificationTypeEnabled(notification.type)) {
            await _popupService.showNotification(notification);
           
            await _markPopupDisplayed(notification.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for reactivated notifications: $e');
    }
  }

  // check all notification types
  Future<void> checkAllNotifications(List<BetelBed> beds) async {
    if (!_notificationsEnabled) {
      debugPrint('Notifications are disabled, skipping all checks');
      return;
    }

    // Check for weather alerts
    await checkWeatherAlerts(beds);

    // Check for harvest time alerts
    await checkHarvestAlerts(beds);

    // Check for fertilizing alerts
    await checkFertilizeAlerts(beds);

    // TODO More notification types can be added here as needed
  }

  // clean up resources
  void dispose() {
    _unsubscribeFromNotifications();
    _onNotificationsChanged = null;
    _popupService.dispose();
  }
}
