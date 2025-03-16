// lib/services/awesome_notification_helper.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/notification_model.dart';

class AwesomeNotificationHelper {
  static final AwesomeNotificationHelper _instance = AwesomeNotificationHelper._internal();
  factory AwesomeNotificationHelper() => _instance;
  
  AwesomeNotificationHelper._internal();
  
  // Show a notification
  Future<bool> showNotification(BetelNotification notification) async {
    try {
      // Get channel based on notification type
      String channelKey;
      Color notificationColor;
      
      switch (notification.type) {
        case NotificationType.weather:
          channelKey = 'weather_channel';
          notificationColor = Colors.blue;
          break;
        case NotificationType.harvest:
          channelKey = 'harvest_channel';
          notificationColor = Colors.green;
          break;
        case NotificationType.fertilize:
          channelKey = 'fertilize_channel';
          notificationColor = Colors.teal;
          break;
        case NotificationType.system:
        default:
          channelKey = 'system_channel';
          notificationColor = Colors.grey;
      }
      
      debugPrint('Creating notification with title: ${notification.title}');
      
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification.id.hashCode.abs().remainder(100000),
          channelKey: channelKey,
          title: notification.title,
          body: notification.message,
          // Don't specify an icon - it will use the default app icon
          notificationLayout: NotificationLayout.Default,
          color: notificationColor,
          // Store the notification ID as a payload to handle taps
          payload: {'id': notification.id},
        ),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }
  
  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}