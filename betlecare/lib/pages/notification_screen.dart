import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/pages/notification_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:betlecare/pages/beds/bed_detail_screen.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
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
    // Filter notifications to only show those from the last 3 days
    final DateTime thresholdDate = DateTime.now().subtract(const Duration(days: 3));
    
    final filteredNotifications = provider.notifications
        .where((notification) => notification.createdAt.isAfter(thresholdDate))
        .toList();
    
    // Sort notifications by date (newest first)
    filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () => provider.loadNotifications(),
      child: ListView.builder(
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
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
        color: Colors.grey.shade200,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.grey.shade700),
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
          onTap: () async {
            // Mark as read if it's unread
            if (isUnread) {
              provider.markAsRead(notification.id);
            }
            
            // If notification is related to a bed, navigate to that bed's detail screen
            if (notification.bedId != null && notification.bedId!.isNotEmpty) {
              // Get the bed provider to find the bed by ID
              final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
              
              // Find the bed that matches the bedId
              final beds = betelBedProvider.beds;
              BetelBed? targetBed;
              
              for (var bed in beds) {
                if (bed.id == notification.bedId) {
                  targetBed = bed;
                  break;
                }
              }
              
              // If the bed is found, navigate to its detail screen
              if (targetBed != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BedDetailScreen(bed: targetBed!),
                  ),
                );
                
                // If returning from the bed detail screen with changes, refresh notifications
                if (result == true) {
                  provider.loadNotifications();
                }
              } else {
                // If bed not found, show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('මෙම වගාව තවදුරටත් පවතින්නේ නැත')), // This bed no longer exists
                );
              }
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