import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'task.g.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Beklemede';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completed:
        return 'Tamamlandı';
      case TaskStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  static TaskStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Düşük';
      case TaskPriority.medium:
        return 'Orta';
      case TaskPriority.high:
        return 'Yüksek';
      case TaskPriority.urgent:
        return 'Acil';
    }
  }

  static TaskPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }
}

@JsonSerializable()
class Task {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'is_calendar_synced')
  final bool isCalendarSynced;

  const Task({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isCalendarSynced = false,
  });

  // Veritabanından gelen veri için constructor
  factory Task.fromDatabase(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.fromString(map['status'] as String),
      priority: TaskPriority.fromString(map['priority'] as String),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isCalendarSynced: (map['is_calendar_synced'] as int) == 1,
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_calendar_synced': isCalendarSynced ? 1 : 0,
    };
  }

  // JSON serialization
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  // Copy with method
  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCalendarSynced,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCalendarSynced: isCalendarSynced ?? this.isCalendarSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.priority == priority &&
        other.dueDate == dueDate &&
        other.isCalendarSynced == isCalendarSynced;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, title, description, status, priority, dueDate, isCalendarSynced);
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, status: ${status.displayName}, priority: ${priority.displayName}}';
  }

  // Formatted tarihler
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(dueDate!);
  }

  // Görevin gecikmiş olup olmadığını kontrol et
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }

  // Görevin bitmesine kalan gün sayısı
  int get daysUntilDue {
    if (dueDate == null) return -1;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference;
  }

  // Görev önceliğine göre renk kodu
  String get priorityColor {
    switch (priority) {
      case TaskPriority.urgent:
        return '#FF5252'; // Red
      case TaskPriority.high:
        return '#FF9800'; // Orange
      case TaskPriority.medium:
        return '#FFC107'; // Amber
      case TaskPriority.low:
        return '#4CAF50'; // Green
    }
  }

  // Görev durumuna göre ikon
  String get statusIcon {
    switch (status) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.inProgress:
        return '🔄';
      case TaskStatus.completed:
        return '✅';
      case TaskStatus.cancelled:
        return '❌';
    }
  }
}