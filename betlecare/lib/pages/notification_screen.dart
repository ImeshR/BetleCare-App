// notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isDevMode = false;
  int _devModeCounter = 0;
  
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
    final betelBedProvider = Provider.of<BetelBedProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Secret tap to enable dev mode
            setState(() {
              _devModeCounter++;
              if (_devModeCounter >= 5) {
                _isDevMode = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Developer mode activated!'))
                );
              }
            });
          },
          child: Text('දැනුම්දීම් (${notificationProvider.unreadCount})'),
        ),
        actions: [
          if (notificationProvider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => notificationProvider.markAllAsRead(),
              tooltip: 'සියල්ල කියවා ඇති ලෙස සලකුණු කරන්න',
            ),
          if (_isDevMode)
            IconButton(
              icon: Icon(notificationProvider.demoMode ? 
                Icons.visibility_off : Icons.visibility),
              onPressed: () {
                notificationProvider.setDemoMode(!notificationProvider.demoMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(notificationProvider.demoMode ? 
                    'Demo mode activated!' : 'Demo mode deactivated!'))
                );
              },
              tooltip: notificationProvider.demoMode ? 'Disable Demo Mode' : 'Enable Demo Mode',
            ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(notificationProvider),
      // Only show in dev mode
      floatingActionButton: _isDevMode && notificationProvider.demoMode && betelBedProvider.beds.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showDemoNotificationMenu(context, betelBedProvider, notificationProvider),
              child: const Icon(Icons.add_alert),
              tooltip: 'Create Demo Notification',
            )
          : null,
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
              // Fixed - no context parameter
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
                  tooltip: 'කියවා ඇති ලෙස සලකුණු කරන්න',
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
  
  // Show demo notification creation menu
  void _showDemoNotificationMenu(
    BuildContext context, 
    BetelBedProvider bedProvider, 
    NotificationProvider notificationProvider
  ) {
    final bed = bedProvider.beds.isNotEmpty ? bedProvider.beds.first : null;
    
    if (bed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a betel bed first'))
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.umbrella, color: Colors.blue),
            title: const Text('Heavy Rainfall Warning'),
            onTap: () {
              notificationProvider.createDemoNotification(
                bed,
                NotificationType.weather,
                metadata: {'weather_type': 'heavy_rain', 'rainfall': 17.8},
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny, color: Colors.orange),
            title: const Text('High Temperature Warning'),
            onTap: () {
              notificationProvider.createDemoNotification(
                bed,
                NotificationType.weather,
                metadata: {'weather_type': 'high_temperature', 'temperature': 37.2},
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.agriculture, color: Colors.green),
            title: const Text('Harvest Time Reminder'),
            onTap: () {
              notificationProvider.createDemoNotification(
                bed,
                NotificationType.harvest,
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.spa, color: Colors.teal),
            title: const Text('Fertilizing Reminder'),
            onTap: () {
              notificationProvider.createDemoNotification(
                bed,
                NotificationType.fertilize,
              );
              Navigator.pop(context);
            },
          ),
        ],
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