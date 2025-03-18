import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/main.dart';

class PopupNotificationService {
  static final PopupNotificationService _instance = PopupNotificationService._internal();
  factory PopupNotificationService() => _instance;
  
  PopupNotificationService._internal();
  
  // Initialize Awesome Notifications
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // No app icon needed, will use default
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for general updates',
          defaultColor: Colors.teal,
          ledColor: Colors.teal,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelGroupKey: 'alerts_channel_group',
          channelKey: 'alerts_channel',
          channelName: 'Alert Notifications',
          channelDescription: 'Urgent notifications that require attention',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic Group',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'alerts_channel_group',
          channelGroupName: 'Alert Group',
        ),
      ],
      debug: true,
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Set up notification action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  // This static method is required for background/terminated notifications
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // When a notification is tapped, navigate to the notification screen
    if (receivedAction.channelKey == 'basic_channel' || 
        receivedAction.channelKey == 'alerts_channel') {
      
      // Use navigation key to navigate without context
      navigatorKey.currentState?.pushNamed('/notifications');
      
      // If notification has an ID in payload, mark it as read
      final notificationId = receivedAction.payload?['notification_id'];
      if (notificationId != null) {
        // We can't directly access the provider here, but we'll handle this 
        // when the notification screen is opened anyway
      }
    }
  }

  // Create a popup notification based on BetelNotification
  Future<void> showNotification(BetelNotification notification) async {
    // Generate unique notification ID based on the notification ID
    // Convert first 8 chars of UUID to integer (to avoid potential overflow)
    int notificationId;
    try {
      notificationId = int.parse(notification.id.substring(0, 8), radix: 16) % 2147483647;
    } catch (e) {
      // Fallback if parsing fails
      notificationId = notification.id.hashCode % 2147483647;
    }
    
    // Choose channel based on notification type
    String channelKey = notification.type == NotificationType.weather ? 
                        'alerts_channel' : 'basic_channel';

    // Show the notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: notification.title,
        body: notification.message,
        notificationLayout: NotificationLayout.Default,
        payload: {
          'notification_id': notification.id,
          'bed_id': notification.bedId ?? '',
          'type': notification.type.toString().split('.').last,
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_READ',
          label: 'කියවා ඇත', // Mark as read
          actionType: ActionType.DismissAction,
        ),
        NotificationActionButton(
          key: 'VIEW',
          label: 'බලන්න', // View
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  // Cleanup
  void dispose() {
    // No need to close action sink in newer version
  }
}