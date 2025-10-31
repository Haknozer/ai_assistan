// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailTemplate _$EmailTemplateFromJson(Map<String, dynamic> json) =>
    EmailTemplate(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String,
      subject: json['subject'] as String?,
      body: json['body'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EmailTemplateToJson(EmailTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'subject': instance.subject,
      'body': instance.body,
      'is_default': instance.isDefault,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
