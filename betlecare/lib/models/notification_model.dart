 
enum NotificationType {
  weather,
  harvest,
  fertilize,
  system
}

enum NotificationStatus {
  active,
  read,
  deleted
}
 
class BetelNotification {
  final String id;
  final String userId;
  final String? bedId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic>? metadata;
  final NotificationStatus status;
  final String? uniqueKey;
  final bool popupDisplayed;  

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
    this.status = NotificationStatus.active,
    this.uniqueKey,
    this.popupDisplayed = false,  
  });

 
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
      status: json['status'] != null
          ? NotificationStatus.values.firstWhere(
              (e) => e.toString() == 'NotificationStatus.${json['status']}',
              orElse: () => NotificationStatus.active,
            )
          : NotificationStatus.active,
      uniqueKey: json['unique_key'],
      popupDisplayed: json['popup_displayed'] ?? false,  
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
      'status': status.toString().split('.').last,
      'unique_key': uniqueKey,
      'popup_displayed': popupDisplayed,  
    };
  }
  
  
  BetelNotification copyWith({
    String? id,
    String? userId,
    String? bedId,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    NotificationType? type,
    Map<String, dynamic>? metadata,
    NotificationStatus? status,
    String? uniqueKey,
    bool? popupDisplayed,  
  }) {
    return BetelNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bedId: bedId ?? this.bedId,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      popupDisplayed: popupDisplayed ?? this.popupDisplayed,  
    );
  }
}