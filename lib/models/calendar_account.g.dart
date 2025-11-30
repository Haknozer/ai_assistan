// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarAccount _$CalendarAccountFromJson(Map<String, dynamic> json) =>
    CalendarAccount(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      emailAddress: json['email_address'] as String,
      provider: $enumDecode(_$CalendarProviderEnumMap, json['provider']),
      displayName: json['display_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastSync: json['last_sync'] == null
          ? null
          : DateTime.parse(json['last_sync'] as String),
      syncEnabled: json['sync_enabled'] as bool? ?? true,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenExpires: json['token_expires'] == null
          ? null
          : DateTime.parse(json['token_expires'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CalendarAccountToJson(CalendarAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'email_address': instance.emailAddress,
      'provider': _$CalendarProviderEnumMap[instance.provider]!,
      'display_name': instance.displayName,
      'is_active': instance.isActive,
      'last_sync': instance.lastSync?.toIso8601String(),
      'sync_enabled': instance.syncEnabled,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_expires': instance.tokenExpires?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$CalendarProviderEnumMap = {
  CalendarProvider.google: 'google',
  CalendarProvider.outlook: 'outlook',
  CalendarProvider.apple: 'apple',
};
