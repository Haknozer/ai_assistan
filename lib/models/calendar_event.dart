import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'calendar_event.g.dart';

enum EventType {
  meeting,
  appointment,
  task,
  personal,
  other;

  String get displayName {
    switch (this) {
      case EventType.meeting:
        return 'Toplantı';
      case EventType.appointment:
        return 'Randevu';
      case EventType.task:
        return 'Görev';
      case EventType.personal:
        return 'Kişisel';
      case EventType.other:
        return 'Diğer';
    }
  }

  static EventType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'meeting':
        return EventType.meeting;
      case 'appointment':
        return EventType.appointment;
      case 'task':
        return EventType.task;
      case 'personal':
        return EventType.personal;
      case 'other':
        return EventType.other;
      default:
        return EventType.personal;
    }
  }
}

enum EventSource {
  manual,
  google,
  outlook,
  apple;

  String get displayName {
    switch (this) {
      case EventSource.manual:
        return 'Manuel';
      case EventSource.google:
        return 'Google Calendar';
      case EventSource.outlook:
        return 'Outlook';
      case EventSource.apple:
        return 'Apple Calendar';
    }
  }

  static EventSource fromString(String source) {
    switch (source.toLowerCase()) {
      case 'manual':
        return EventSource.manual;
      case 'google':
        return EventSource.google;
      case 'outlook':
        return EventSource.outlook;
      case 'apple':
        return EventSource.apple;
      default:
        return EventSource.manual;
    }
  }
}

@JsonSerializable()
class CalendarEvent {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String title;
  final String? description;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime endTime;
  final String? location;
  @JsonKey(name: 'event_type')
  final EventType eventType;
  final EventSource source;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CalendarEvent({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.eventType = EventType.personal,
    this.source = EventSource.manual,
    this.externalId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Veritabanından gelen veri için constructor
  factory CalendarEvent.fromDatabase(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      location: map['location'] as String?,
      eventType: EventType.fromString(map['event_type'] as String),
      source: EventSource.fromString(map['source'] as String),
      externalId: map['external_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'event_type': eventType.name,
      'source': source.name,
      'external_id': externalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);

  // Copy with method
  CalendarEvent copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventType? eventType,
    EventSource? source,
    String? externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.location == location &&
        other.eventType == eventType &&
        other.source == source &&
        other.externalId == externalId;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, title, description, startTime, endTime, location, eventType, source, externalId);
  }

  @override
  String toString() {
    return 'CalendarEvent{id: $id, title: $title, startTime: $startTime, endTime: $endTime}';
  }

  // Formatted tarihler
  String get formattedStartTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(startTime);
  }

  String get formattedEndTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(endTime);
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(startTime);
  }

  String get formattedTime {
    return '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
  }

  // Etkinlik süresi (dakika cinsinden)
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Etkinliğin tam gün olup olmadığını kontrol et
  bool get isAllDay {
    return durationInMinutes >= 24 * 60; // 24 saat veya daha fazla
  }

  // Etkinliğin şu anda devam edip etmediğini kontrol et
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Etkinliğin gelecekte olup olmadığını kontrol et
  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  // Etkinliğin geçmişte olup olmadığını kontrol et
  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  // Etkinliğe kalan süre
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    }
    return Duration.zero;
  }

  // Etkinlik türüne göre renk
  String get eventTypeColor {
    switch (eventType) {
      case EventType.meeting:
        return '#2196F3'; // Blue
      case EventType.appointment:
        return '#9C27B0'; // Purple
      case EventType.task:
        return '#4CAF50'; // Green
      case EventType.personal:
        return '#FF9800'; // Orange
      case EventType.other:
        return '#757575'; // Grey
    }
  }

  // Etkinlik türüne göre ikon
  String get eventTypeIcon {
    switch (eventType) {
      case EventType.meeting:
        return '👥';
      case EventType.appointment:
        return '📅';
      case EventType.task:
        return '✓';
      case EventType.personal:
        return '👤';
      case EventType.other:
        return '📌';
    }
  }

  // Kaynağa göre ikon
  String get sourceIcon {
    switch (source) {
      case EventSource.manual:
        return '✏️';
      case EventSource.google:
        return '🔵';
      case EventSource.outlook:
        return '🔷';
      case EventSource.apple:
        return '🍎';
    }
  }
}
