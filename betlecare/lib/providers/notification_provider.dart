// notification_provider.dart
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:flutter/foundation.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/services/notification_service.dart';

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
}