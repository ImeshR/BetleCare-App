import 'package:betlecare/pages/notification_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:intl/intl.dart';
 

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('දැනුම්දීම් (${notificationProvider.unreadCount})'),
        actions: [
          // Settings icon to navigate to notification preferences
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
            tooltip: 'දැනුම්දීම් සැකසුම්', // Notification Settings
          ),
          if (notificationProvider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => notificationProvider.markAllAsRead(),
              tooltip: 'සියල්ල කියවා ඇති ලෙස සලකුණු කරන්න', // Mark all as read
            ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(notificationProvider),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'දැනුම්දීම් නොමැත',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ඔබට නව දැනුම්දීමක් ලැබුණු විට එය මෙහි පෙන්වනු ඇත',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                .checkAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for new notifications...'))
              );
            },
            child: const Text('Check for Notifications'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationList(NotificationProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadNotifications(),
      child: ListView.builder(
        itemCount: provider.notifications.length,
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return _buildNotificationItem(notification, provider);
        },
      ),
    );
  }
  
  Widget _buildNotificationItem(BetelNotification notification, NotificationProvider provider) {
    final isUnread = !notification.isRead;
    
    // Get icon and color based on notification type
    IconData icon;
    Color color;
    
    switch (notification.type) {
      case NotificationType.weather:
        final weatherType = notification.metadata?['weather_type'];
        if (weatherType == 'heavy_rain') {
          icon = Icons.umbrella;
          color = Colors.blue;
        } else if (weatherType == 'high_temperature') {
          icon = Icons.wb_sunny;
          color = Colors.orange;
        } else {
          icon = Icons.cloud;
          color = Colors.indigo;
        }
        break;
      case NotificationType.harvest:
        icon = Icons.agriculture;
        color = Colors.green;
        break;
      case NotificationType.fertilize:
        icon = Icons.spa;
        color = Colors.teal;
        break;
      case NotificationType.system:
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
      },
      child: Container(
        color: isUnread ? Colors.blue.withOpacity(0.05) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: isUnread
              ? IconButton(
                  icon: const Icon(Icons.mark_email_read, size: 20),
                  onPressed: () => provider.markAsRead(notification.id),
                  tooltip: 'කියවා ඇති ලෙස සලකුණු කරන්න', // Mark as read
                )
              : null,
          onTap: () {
            if (isUnread) {
              provider.markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'අද ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'ඊයේ ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }
}