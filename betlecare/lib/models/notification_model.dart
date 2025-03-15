// notification_model.dart
enum NotificationType {
  weather,
  harvest,
  fertilize,
  system
}

class BetelNotification {
  final String id;
  final String userId;
  final String? bedId; // Optional - may be null for general notifications
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic>? metadata;

  BetelNotification({
    required this.id,
    required this.userId,
    this.bedId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.metadata,
  });

  // Convert to/from Supabase
  factory BetelNotification.fromJson(Map<String, dynamic> json) {
    return BetelNotification(
      id: json['id'],
      userId: json['user_id'],
      bedId: json['bed_id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.system,
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bed_id': bedId,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }
}