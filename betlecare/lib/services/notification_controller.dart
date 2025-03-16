// lib/services/notification_controller.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:betlecare/main.dart';
import 'package:flutter/material.dart';

// This class needs to be outside any other class to be accessible globally
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.id}');
    
    // Navigate to notification screen when user taps the notification
    if (navigatorKey.currentContext != null && receivedAction.actionType == ActionType.Default) {
      await Navigator.of(navigatorKey.currentContext!).pushNamed('/notifications');
    }
  }

  // This method initializes the notifications features
  static Future<void> initializeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        // Use null instead of a specific icon - this will use the app icon automatically
        null,
        [
          NotificationChannel(
            channelKey: 'weather_channel',
            channelName: 'Weather Alerts',
            channelDescription: 'Weather related alerts for your plants',
            defaultColor: Colors.blue,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'harvest_channel',
            channelName: 'Harvest Reminders',
            channelDescription: 'Reminders for harvest times',
            defaultColor: Colors.green,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'fertilize_channel',
            channelName: 'Fertilize Reminders',
            channelDescription: 'Reminders for fertilizing your plants',
            defaultColor: Colors.teal,
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: 'system_channel',
            channelName: 'System Notifications',
            channelDescription: 'System related notifications',
            defaultColor: Colors.grey,
            importance: NotificationImportance.Default,
            channelShowBadge: true,
          ),
        ],
      );

      // Always request permission
      await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          AwesomeNotifications().requestPermissionToSendNotifications();
        }
      });

      // Set the notification action listeners
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );
      
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Use this method to create a test notification
  static Future<void> createTestNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'system_channel',
          title: 'Test Notification',
          body: 'This is a test notification to make sure everything is working!',
          // Don't specify an icon - it will use the default app icon
          notificationLayout: NotificationLayout.Default,
        ),
      );
      debugPrint('Test notification created successfully');
    } catch (e) {
      debugPrint('Error creating test notification: $e');
    }
  }
}