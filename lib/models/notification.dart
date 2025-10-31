import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'notification.g.dart';

enum NotificationType {
  task,
  calendar,
  email,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.task:
        return 'Görev';
      case NotificationType.calendar:
        return 'Takvim';
      case NotificationType.email:
        return 'E-posta';
      case NotificationType.system:
        return 'Sistem';
    }
  }

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return NotificationType.task;
      case 'calendar':
        return NotificationType.calendar;
      case 'email':
        return NotificationType.email;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}

@JsonSerializable()
class Notification {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String title;
  final String message;
  final NotificationType type;
  @JsonKey(name: 'related_id')
  final int? relatedId;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'scheduled_for')
  final DateTime? scheduledFor;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Notification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    this.scheduledFor,
    required this.createdAt,
  });

  // Veritabanından gelen veri için constructor
  factory Notification.fromDatabase(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      type: NotificationType.fromString(map['type'] as String),
      relatedId: map['related_id'] as int?,
      isRead: (map['is_read'] as int) == 1,
      scheduledFor: map['scheduled_for'] != null ? DateTime.parse(map['scheduled_for'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'related_id': relatedId,
      'is_read': isRead ? 1 : 0,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  // Copy with method
  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? type,
    int? relatedId,
    bool? isRead,
    DateTime? scheduledFor,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.relatedId == relatedId &&
        other.isRead == isRead &&
        other.scheduledFor == scheduledFor;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, title, message, type, relatedId, isRead, scheduledFor);
  }

  @override
  String toString() {
    return 'Notification{id: $id, title: $title, type: ${type.displayName}, isRead: $isRead}';
  }

  // Formatted tarihler
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedScheduledFor {
    if (scheduledFor == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(scheduledFor!);
  }

  // Bildirimin planlandığı zamanın ne kadar kadar olduğunu hesapla
  Duration? get timeUntilScheduled {
    if (scheduledFor == null) return null;
    return scheduledFor!.difference(DateTime.now());
  }

  // Bildirimin zamanı gelmiş mi
  bool get isTimeToShow {
    if (scheduledFor == null) return true;
    return DateTime.now().isAfter(scheduledFor!);
  }

  // Bildirimin ne kadar süre önce oluşturulduğunu hesapla
  Duration get timeSinceCreated {
    return DateTime.now().difference(createdAt);
  }

  // Göreceli zaman gösterimi
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // Bildirim türüne göre ikon
  String get typeIcon {
    switch (type) {
      case NotificationType.task:
        return '✓';
      case NotificationType.calendar:
        return '📅';
      case NotificationType.email:
        return '📧';
      case NotificationType.system:
        return '⚙️';
    }
  }

  // Bildirim türüne göre renk
  String get typeColor {
    switch (type) {
      case NotificationType.task:
        return '#4CAF50'; // Green
      case NotificationType.calendar:
        return '#2196F3'; // Blue
      case NotificationType.email:
        return '#FF9800'; // Orange
      case NotificationType.system:
        return '#9E9E9E'; // Grey
    }
  }

  // Okunma durumuna göre stil
  String get readStatus {
    return isRead ? 'Okundu' : 'Okunmadı';
  }

  // Okunma durumuna göre ikon
  String get readStatusIcon {
    return isRead ? '✅' : '🔵';
  }
}