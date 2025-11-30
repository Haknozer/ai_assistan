import 'package:json_annotation/json_annotation.dart';

part 'calendar_account.g.dart';

enum CalendarProvider {
  google,
  outlook,
  apple;

  String get displayName {
    switch (this) {
      case CalendarProvider.google:
        return 'Google Calendar';
      case CalendarProvider.outlook:
        return 'Outlook Calendar';
      case CalendarProvider.apple:
        return 'Apple Calendar';
    }
  }

  static CalendarProvider fromString(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return CalendarProvider.google;
      case 'outlook':
        return CalendarProvider.outlook;
      case 'apple':
        return CalendarProvider.apple;
      default:
        return CalendarProvider.google;
    }
  }
}

@JsonSerializable()
class CalendarAccount {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'email_address')
  final String emailAddress;
  final CalendarProvider provider;
  @JsonKey(name: 'display_name')
  final String? displayName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_sync')
  final DateTime? lastSync;
  @JsonKey(name: 'sync_enabled')
  final bool syncEnabled;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'token_expires')
  final DateTime? tokenExpires;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CalendarAccount({
    this.id,
    required this.userId,
    required this.emailAddress,
    required this.provider,
    this.displayName,
    this.isActive = true,
    this.lastSync,
    this.syncEnabled = true,
    this.accessToken,
    this.refreshToken,
    this.tokenExpires,
    required this.createdAt,
    required this.updatedAt,
  });

  // Veritabanından gelen veri için constructor
  factory CalendarAccount.fromDatabase(Map<String, dynamic> map) {
    return CalendarAccount(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      emailAddress: map['email_address'] as String,
      provider: CalendarProvider.fromString(map['provider'] as String),
      displayName: map['display_name'] as String?,
      isActive: (map['is_active'] as int) == 1,
      lastSync: map['last_sync'] != null ? DateTime.parse(map['last_sync'] as String) : null,
      syncEnabled: (map['sync_enabled'] as int) == 1,
      accessToken: map['access_token'] as String?,
      refreshToken: map['refresh_token'] as String?,
      tokenExpires: map['token_expires'] != null ? DateTime.parse(map['token_expires'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'email_address': emailAddress,
      'provider': provider.name,
      'display_name': displayName,
      'is_active': isActive ? 1 : 0,
      'last_sync': lastSync?.toIso8601String(),
      'sync_enabled': syncEnabled ? 1 : 0,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires': tokenExpires?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory CalendarAccount.fromJson(Map<String, dynamic> json) => _$CalendarAccountFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarAccountToJson(this);

  // Copy with method
  CalendarAccount copyWith({
    int? id,
    int? userId,
    String? emailAddress,
    CalendarProvider? provider,
    String? displayName,
    bool? isActive,
    DateTime? lastSync,
    bool? syncEnabled,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpires,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emailAddress: emailAddress ?? this.emailAddress,
      provider: provider ?? this.provider,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      lastSync: lastSync ?? this.lastSync,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpires: tokenExpires ?? this.tokenExpires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
