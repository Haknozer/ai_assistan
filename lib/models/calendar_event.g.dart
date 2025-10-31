// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    CalendarEvent(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      eventType: $enumDecodeNullable(_$EventTypeEnumMap, json['event_type']) ??
          EventType.personal,
      source: $enumDecodeNullable(_$EventSourceEnumMap, json['source']) ??
          EventSource.manual,
      externalId: json['external_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CalendarEventToJson(CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'location': instance.location,
      'event_type': _$EventTypeEnumMap[instance.eventType]!,
      'source': _$EventSourceEnumMap[instance.source]!,
      'external_id': instance.externalId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$EventTypeEnumMap = {
  EventType.meeting: 'meeting',
  EventType.appointment: 'appointment',
  EventType.task: 'task',
  EventType.personal: 'personal',
  EventType.other: 'other',
};

const _$EventSourceEnumMap = {
  EventSource.manual: 'manual',
  EventSource.google: 'google',
  EventSource.outlook: 'outlook',
  EventSource.apple: 'apple',
};
