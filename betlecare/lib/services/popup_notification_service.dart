import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/main.dart';

class PopupNotificationService {
  static final PopupNotificationService _instance = PopupNotificationService._internal();
  factory PopupNotificationService() => _instance;
  
  PopupNotificationService._internal();
  
 
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, 
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

    // request permission to show notifications if not allowed
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }


  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
   
    if (receivedAction.channelKey == 'basic_channel' || 
        receivedAction.channelKey == 'alerts_channel') {
      
      
      navigatorKey.currentState?.pushNamed('/notifications');
      final notificationId = receivedAction.payload?['notification_id'];
      if (notificationId != null) {

      }
    }
  }

  // create a popup notification based on BetelNotification
  Future<void> showNotification(BetelNotification notification) async {

    int notificationId;
    try {
      notificationId = int.parse(notification.id.substring(0, 8), radix: 16) % 2147483647;
    } catch (e) {

      notificationId = notification.id.hashCode % 2147483647;
    }
    

    String channelKey = notification.type == NotificationType.weather ? 
                        'alerts_channel' : 'basic_channel';


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
          label: 'කියවා ඇත', 
          actionType: ActionType.DismissAction,
        ),
        NotificationActionButton(
          key: 'VIEW',
          label: 'බලන්න', 
          actionType: ActionType.Default,
        ),
      ],
    );
  }


  void dispose() {
    
  }
}