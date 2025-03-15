// notification_provider.dart with improved real-time updates
import 'package:flutter/material.dart';
import 'package:betlecare/models/notification_model.dart';
import 'package:betlecare/models/betel_bed_model.dart';
import 'package:betlecare/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:betlecare/main.dart';
import 'dart:async'; // Import for Timer

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<BetelNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _error;
  DateTime _lastCheck = DateTime.now().subtract(const Duration(hours: 1)); // Track last check time
  Timer? _refreshTimer; // Add refresh timer
  
  List<BetelNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get error => _error;
  bool get demoMode => _notificationService.demoMode;
  
  // Initialize
  Future<void> initialize() async {
    debugPrint('Initializing NotificationProvider');
    await _notificationService.initialize();
    
    // Register callback for real-time updates
    _notificationService.setNotificationCallback(_onNotificationsChanged);
    
    // First load
    await loadNotifications();
    
    // Set up periodic refresh timer as a fallback (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      debugPrint('🔄 Periodic notification refresh timer fired');
      refreshUnreadCount();
    });
    
    // Refresh subscription after a delay to ensure connection is stable
    Future.delayed(const Duration(seconds: 5), () {
      _notificationService.refreshSubscription();
    });
  }
  
  // Callback function for real-time notifications
  void _onNotificationsChanged() {
    debugPrint('⚡ Real-time notification update received');
    refreshUnreadCount(); // Just update the count first (faster)
    loadNotifications(); // Then load the full notifications list
  }
  
  // Refresh just the unread count (lighter operation)
  Future<void> refreshUnreadCount() async {
    try {
      final newCount = await _notificationService.getUnreadCount();
      if (newCount != _unreadCount) {
        debugPrint('📊 Unread count changed: $_unreadCount -> $newCount');
        _unreadCount = newCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing unread count: $e');
    }
  }
  
  // Toggle demo mode
  Future<void> setDemoMode(bool value) async {
    await _notificationService.setDemoMode(value);
    await loadNotifications();
    notifyListeners();
  }
  
  // Force refresh the notification subscription
  Future<void> refreshSubscription() async {
    debugPrint('🔄 Force refreshing notification subscription');
    await _notificationService.refreshSubscription();
    await loadNotifications();
  }
  
  // Load notifications
  Future<void> loadNotifications() async {
    try {
      if (_isLoading) {
        debugPrint('⚠️ Already loading notifications, skipping');
        return;
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      debugPrint('🔍 Loading notifications...');
      _notifications = await _notificationService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      
      _isLoading = false;
      debugPrint('✅ Loaded ${_notifications.length} notifications, $_unreadCount unread');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('❌ Error loading notifications: $_error');
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
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          status: NotificationStatus.read,
        );
        
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error marking notification as read: $_error');
      notifyListeners();
    }
  }
  
  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        status: NotificationStatus.read,
      )).toList();
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error marking all notifications as read: $_error');
      notifyListeners();
    }
  }
  
  // Delete notification - fixed version with null safety
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Get the unique key before removing
      String uniqueKey = '';
      
      // Find the notification without using firstWhere with null
      BetelNotification? foundNotification;
      for (final n in _notifications) {
        if (n.id == notificationId) {
          foundNotification = n;
          break;
        }
      }
      
      // Use the uniqueKey if found
      if (foundNotification != null && foundNotification.uniqueKey != null) {
        uniqueKey = foundNotification.uniqueKey!;
      }
      
      await _notificationService.deleteNotification(notificationId, uniqueKey);
      
      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting notification: $_error');
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
      debugPrint('❌ Error creating demo notification: $_error');
      notifyListeners();
    }
  }
  
  // Check all notifications (weather, harvest, fertilize) with debounce
  Future<void> checkAllNotifications() async {
    // Debounce: don't check more often than every 30 minutes
    final now = DateTime.now();
    if (now.difference(_lastCheck).inMinutes < 30) {
      debugPrint('⏳ Notification check debounced - last check was ${now.difference(_lastCheck).inMinutes} minutes ago');
      return;
    }
    
    try {
      debugPrint('🔍 Checking for new notifications...');
      _lastCheck = now;
      
      // Get beds from BetelBedProvider
      final context = navigatorKey.currentContext;
      if (context == null) return;
      
      final betelBedProvider = Provider.of<BetelBedProvider>(context, listen: false);
      final beds = betelBedProvider.beds;
      
      if (beds.isEmpty) {
        debugPrint('⚠️ No beds available for notification check');
        return;
      }
      
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
      
      // Real-time updates will handle notification refresh
      debugPrint('✅ Notification check completed');
    } catch (e) {
      debugPrint('❌ Error checking for notifications: $e');
    }
  }
  
  // Clean up when provider is disposed
  @override
  void dispose() {
    debugPrint('Disposing NotificationProvider');
    _refreshTimer?.cancel();
    _notificationService.removeNotificationCallback();
    _notificationService.dispose();
    super.dispose();
  }
}