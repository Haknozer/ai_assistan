import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'email_analytics.g.dart';

enum EmailCategory {
  important,
  promotional,
  social,
  spam,
  personal,
  work;

  String get displayName {
    switch (this) {
      case EmailCategory.important:
        return 'Önemli';
      case EmailCategory.promotional:
        return 'Promosyon';
      case EmailCategory.social:
        return 'Sosyal';
      case EmailCategory.spam:
        return 'Spam';
      case EmailCategory.personal:
        return 'Kişisel';
      case EmailCategory.work:
        return 'İş';
    }
  }

  static EmailCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return EmailCategory.important;
      case 'promotional':
        return EmailCategory.promotional;
      case 'social':
        return EmailCategory.social;
      case 'spam':
        return EmailCategory.spam;
      case 'personal':
        return EmailCategory.personal;
      case 'work':
        return EmailCategory.work;
      default:
        return EmailCategory.personal;
    }
  }
}

enum EmailPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case EmailPriority.high:
        return 'Yüksek';
      case EmailPriority.medium:
        return 'Orta';
      case EmailPriority.low:
        return 'Düşük';
    }
  }

  static EmailPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return EmailPriority.high;
      case 'medium':
        return EmailPriority.medium;
      case 'low':
        return EmailPriority.low;
      default:
        return EmailPriority.medium;
    }
  }
}

@JsonSerializable()
class EmailAnalytics {
  final int? id;
  @JsonKey(name: 'account_id')
  final int accountId;
  @JsonKey(name: 'message_id')
  final String messageId;
  final String? sender;
  final String? subject;
  @JsonKey(name: 'ai_category')
  final EmailCategory? aiCategory;
  @JsonKey(name: 'ai_priority')
  final EmailPriority? aiPriority;
  @JsonKey(name: 'ai_summary')
  final String? aiSummary;
  @JsonKey(name: 'extracted_tasks')
  final List<String>? extractedTasks;
  @JsonKey(name: 'extracted_events')
  final List<String>? extractedEvents;
  @JsonKey(name: 'is_processed')
  final bool isProcessed;
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const EmailAnalytics({
    this.id,
    required this.accountId,
    required this.messageId,
    this.sender,
    this.subject,
    this.aiCategory,
    this.aiPriority,
    this.aiSummary,
    this.extractedTasks,
    this.extractedEvents,
    this.isProcessed = false,
    this.processedAt,
    required this.createdAt,
  });

  // Veritabanından gelen veri için constructor
  factory EmailAnalytics.fromDatabase(Map<String, dynamic> map) {
    return EmailAnalytics(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      messageId: map['message_id'] as String,
      sender: map['sender'] as String?,
      subject: map['subject'] as String?,
      aiCategory: map['ai_category'] != null ? EmailCategory.fromString(map['ai_category'] as String) : null,
      aiPriority: map['ai_priority'] != null ? EmailPriority.fromString(map['ai_priority'] as String) : null,
      aiSummary: map['ai_summary'] as String?,
      extractedTasks: map['extracted_tasks'] != null ? List<String>.from(map['extracted_tasks'] as List) : null,
      extractedEvents: map['extracted_events'] != null ? List<String>.from(map['extracted_events'] as List) : null,
      isProcessed: (map['is_processed'] as int) == 1,
      processedAt: map['processed_at'] != null ? DateTime.parse(map['processed_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'message_id': messageId,
      'sender': sender,
      'subject': subject,
      'ai_category': aiCategory?.name,
      'ai_priority': aiPriority?.name,
      'ai_summary': aiSummary,
      'extracted_tasks': extractedTasks != null ? '[${extractedTasks!.map((e) => '"$e"').join(',')}]' : null,
      'extracted_events': extractedEvents != null ? '[${extractedEvents!.map((e) => '"$e"').join(',')}]' : null,
      'is_processed': isProcessed ? 1 : 0,
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory EmailAnalytics.fromJson(Map<String, dynamic> json) => _$EmailAnalyticsFromJson(json);
  Map<String, dynamic> toJson() => _$EmailAnalyticsToJson(this);

  // Copy with method
  EmailAnalytics copyWith({
    int? id,
    int? accountId,
    String? messageId,
    String? sender,
    String? subject,
    EmailCategory? aiCategory,
    EmailPriority? aiPriority,
    String? aiSummary,
    List<String>? extractedTasks,
    List<String>? extractedEvents,
    bool? isProcessed,
    DateTime? processedAt,
    DateTime? createdAt,
  }) {
    return EmailAnalytics(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      messageId: messageId ?? this.messageId,
      sender: sender ?? this.sender,
      subject: subject ?? this.subject,
      aiCategory: aiCategory ?? this.aiCategory,
      aiPriority: aiPriority ?? this.aiPriority,
      aiSummary: aiSummary ?? this.aiSummary,
      extractedTasks: extractedTasks ?? this.extractedTasks,
      extractedEvents: extractedEvents ?? this.extractedEvents,
      isProcessed: isProcessed ?? this.isProcessed,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailAnalytics &&
        other.id == id &&
        other.accountId == accountId &&
        other.messageId == messageId &&
        other.sender == sender &&
        other.subject == subject &&
        other.aiCategory == aiCategory &&
        other.aiPriority == aiPriority &&
        other.aiSummary == aiSummary &&
        other.isProcessed == isProcessed;
  }

  @override
  int get hashCode {
    return Object.hash(id, accountId, messageId, sender, subject, aiCategory, aiPriority, aiSummary, isProcessed);
  }

  @override
  String toString() {
    return 'EmailAnalytics{id: $id, messageId: $messageId, sender: $sender, category: ${aiCategory?.displayName}}';
  }

  // Formatted tarihler
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedProcessedAt {
    if (processedAt == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(processedAt!);
  }

  // Görev ve etkinlik sayıları
  int get extractedTasksCount => extractedTasks?.length ?? 0;
  int get extractedEventsCount => extractedEvents?.length ?? 0;

  // Kategoriye göre renk
  String get categoryColor {
    switch (aiCategory) {
      case EmailCategory.important:
        return '#F44336'; // Red
      case EmailCategory.promotional:
        return '#FF9800'; // Orange
      case EmailCategory.social:
        return '#2196F3'; // Blue
      case EmailCategory.spam:
        return '#9E9E9E'; // Grey
      case EmailCategory.personal:
        return '#4CAF50'; // Green
      case EmailCategory.work:
        return '#9C27B0'; // Purple
      case null:
        return '#757575'; // Grey
    }
  }

  // Önceliğe göre renk
  String get priorityColor {
    switch (aiPriority) {
      case EmailPriority.high:
        return '#F44336'; // Red
      case EmailPriority.medium:
        return '#FF9800'; // Orange
      case EmailPriority.low:
        return '#4CAF50'; // Green
      case null:
        return '#757575'; // Grey
    }
  }

  // Kategoriye göre ikon
  String get categoryIcon {
    switch (aiCategory) {
      case EmailCategory.important:
        return '⭐';
      case EmailCategory.promotional:
        return '🛍️';
      case EmailCategory.social:
        return '👥';
      case EmailCategory.spam:
        return '🗑️';
      case EmailCategory.personal:
        return '👤';
      case EmailCategory.work:
        return '💼';
      case null:
        return '📧';
    }
  }

  // Önceliğe göre ikon
  String get priorityIcon {
    switch (aiPriority) {
      case EmailPriority.high:
        return '🔴';
      case EmailPriority.medium:
        return '🟡';
      case EmailPriority.low:
        return '🟢';
      case null:
        return '⚪';
    }
  }

  // İşleme durumuna göre metin
  String get processingStatus {
    if (isProcessed) {
      return 'İşlendi';
    } else {
      return 'Beklemede';
    }
  }

  // Özetin uzunluğunu kontrol et
  bool get hasSummary => aiSummary != null && aiSummary!.isNotEmpty;
  bool get hasExtractedTasks => extractedTasks != null && extractedTasks!.isNotEmpty;
  bool get hasExtractedEvents => extractedEvents != null && extractedEvents!.isNotEmpty;
}