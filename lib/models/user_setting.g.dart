// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSetting _$UserSettingFromJson(Map<String, dynamic> json) => UserSetting(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      settingKey: json['setting_key'] as String,
      settingValue: json['setting_value'] as String?,
      category:
          $enumDecodeNullable(_$SettingCategoryEnumMap, json['category']) ??
              SettingCategory.general,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserSettingToJson(UserSetting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'setting_key': instance.settingKey,
      'setting_value': instance.settingValue,
      'category': _$SettingCategoryEnumMap[instance.category]!,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$SettingCategoryEnumMap = {
  SettingCategory.general: 'general',
  SettingCategory.notifications: 'notifications',
  SettingCategory.email: 'email',
  SettingCategory.calendar: 'calendar',
  SettingCategory.privacy: 'privacy',
  SettingCategory.ai: 'ai',
};
