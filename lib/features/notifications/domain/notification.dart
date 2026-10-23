class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );
  }
}

enum NotificationSyncState { synchronized, stale, offline, rejected }

class NotificationSnapshot {
  const NotificationSnapshot({
    required this.notifications,
    required this.state,
    this.lastSyncedAt,
    this.rejectedWrite,
  });

  final List<AppNotification> notifications;
  final NotificationSyncState state;
  final DateTime? lastSyncedAt;
  final String? rejectedWrite;
}
