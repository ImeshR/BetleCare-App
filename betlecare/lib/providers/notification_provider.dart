// notification_provider.dart
import 'package:betlecare/main.dart';
import 'package:flutter/foundation.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:flutter/material.dart';
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<BetelNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _error;
  
  List<BetelNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get error => _error;
  bool get demoMode => _notificationService.demoMode;
  
  // Initialize
  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadNotifications();
  }
  
  // Toggle demo mode
  Future<void> setDemoMode(bool value) async {
    await _notificationService.setDemoMode(value);
    await loadNotifications();
    notifyListeners();
  }
  
  // Load notifications
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _notifications = await _notificationService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        _notifications[index] = BetelNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          bedId: _notifications[index].bedId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          type: _notifications[index].type,
          metadata: _notifications[index].metadata,
        );
        
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      _notifications = _notifications.map((n) => BetelNotification(
        id: n.id,
        userId: n.userId,
        bedId: n.bedId,
        title: n.title,
        message: n.message,
        createdAt: n.createdAt,
        isRead: true,
        type: n.type,
        metadata: n.metadata,
      )).toList();
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Create demo notification
  Future<void> createDemoNotification(
    BetelBed bed, 
    NotificationType type, 
    {Map<String, dynamic>? metadata}
  ) async {
    try {
      await _notificationService.createDemoNotification(bed, type, metadata: metadata);
      await loadNotifications(); // Reload notifications
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // At the top of notification_provider.dart, add this if it's not already there:


// Change the checkAllNotifications method to this:
Future<void> checkAllNotifications() async {
  try {
    // Get beds from BetelBedProvider using the global navigator key
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
    final beds = betelBedProvider.beds;
    
    // Check for weather alerts
    await _notificationService.checkWeatherAlerts(beds);
    
    // Check for harvest time alerts
    await _notificationService.checkHarvestAlerts(beds);
    
    // Check for fertilizing alerts
    for (final bed in beds) {
      if (bed.daysUntilNextFertilizing <= 3 && bed.daysUntilNextFertilizing > 0) {
        await _notificationService.createNotification(
          title: 'පොහොර යෙදීමේ කාලය ළඟයි',
          message: '${bed.name} සඳහා පොහොර යෙදීම සිදු කිරීමට තව දින ${bed.daysUntilNextFertilizing}ක් පමණි.',
          type: NotificationType.fertilize,
          bedId: bed.id,
          metadata: {'days_until_fertilizing': bed.daysUntilNextFertilizing},
        );
      }
    }
    
    // Reload notifications to show the new ones
    await loadNotifications();
  } catch (e) {
    print('Error checking for notifications: $e');
  }
}

}