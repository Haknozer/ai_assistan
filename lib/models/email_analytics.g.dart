// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailAnalytics _$EmailAnalyticsFromJson(Map<String, dynamic> json) =>
    EmailAnalytics(
      id: (json['id'] as num?)?.toInt(),
      accountId: (json['account_id'] as num).toInt(),
      messageId: json['message_id'] as String,
      sender: json['sender'] as String?,
      subject: json['subject'] as String?,
      aiCategory:
          $enumDecodeNullable(_$EmailCategoryEnumMap, json['ai_category']),
      aiPriority:
          $enumDecodeNullable(_$EmailPriorityEnumMap, json['ai_priority']),
      aiSummary: json['ai_summary'] as String?,
      extractedTasks: (json['extracted_tasks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      extractedEvents: (json['extracted_events'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isProcessed: json['is_processed'] as bool? ?? false,
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.parse(json['processed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$EmailAnalyticsToJson(EmailAnalytics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'message_id': instance.messageId,
      'sender': instance.sender,
      'subject': instance.subject,
      'ai_category': _$EmailCategoryEnumMap[instance.aiCategory],
      'ai_priority': _$EmailPriorityEnumMap[instance.aiPriority],
      'ai_summary': instance.aiSummary,
      'extracted_tasks': instance.extractedTasks,
      'extracted_events': instance.extractedEvents,
      'is_processed': instance.isProcessed,
      'processed_at': instance.processedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$EmailCategoryEnumMap = {
  EmailCategory.important: 'important',
  EmailCategory.promotional: 'promotional',
  EmailCategory.social: 'social',
  EmailCategory.spam: 'spam',
  EmailCategory.personal: 'personal',
  EmailCategory.work: 'work',
};

const _$EmailPriorityEnumMap = {
  EmailPriority.high: 'high',
  EmailPriority.medium: 'medium',
  EmailPriority.low: 'low',
};
