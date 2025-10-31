// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      relatedId: (json['related_id'] as num?)?.toInt(),
      isRead: json['is_read'] as bool? ?? false,
      scheduledFor: json['scheduled_for'] == null
          ? null
          : DateTime.parse(json['scheduled_for'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'related_id': instance.relatedId,
      'is_read': instance.isRead,
      'scheduled_for': instance.scheduledFor?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.task: 'task',
  NotificationType.calendar: 'calendar',
  NotificationType.email: 'email',
  NotificationType.system: 'system',
};
