import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'email_account.g.dart';

enum EmailProvider {
  gmail,
  outlook,
  yahoo;

  String get displayName {
    switch (this) {
      case EmailProvider.gmail:
        return 'Gmail';
      case EmailProvider.outlook:
        return 'Outlook';
      case EmailProvider.yahoo:
        return 'Yahoo';
    }
  }

  static EmailProvider fromString(String provider) {
    switch (provider.toLowerCase()) {
      case 'gmail':
        return EmailProvider.gmail;
      case 'outlook':
        return EmailProvider.outlook;
      case 'yahoo':
        return EmailProvider.yahoo;
      default:
        return EmailProvider.gmail;
    }
  }

  String get imapServer {
    switch (this) {
      case EmailProvider.gmail:
        return 'imap.gmail.com';
      case EmailProvider.outlook:
        return 'outlook.office365.com';
      case EmailProvider.yahoo:
        return 'imap.mail.yahoo.com';
    }
  }

  String get smtpServer {
    switch (this) {
      case EmailProvider.gmail:
        return 'smtp.gmail.com';
      case EmailProvider.outlook:
        return 'smtp-mail.outlook.com';
      case EmailProvider.yahoo:
        return 'smtp.mail.yahoo.com';
    }
  }

  int get imapPort => 993;
  int get smtpPort => 587;
}

@JsonSerializable()
class EmailAccount {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'email_address')
  final String emailAddress;
  final EmailProvider provider;
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

  const EmailAccount({
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
  factory EmailAccount.fromDatabase(Map<String, dynamic> map) {
    return EmailAccount(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      emailAddress: map['email_address'] as String,
      provider: EmailProvider.fromString(map['provider'] as String),
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
  factory EmailAccount.fromJson(Map<String, dynamic> json) => _$EmailAccountFromJson(json);
  Map<String, dynamic> toJson() => _$EmailAccountToJson(this);

  // Copy with method
  EmailAccount copyWith({
    int? id,
    int? userId,
    String? emailAddress,
    EmailProvider? provider,
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
    return EmailAccount(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailAccount &&
        other.id == id &&
        other.userId == userId &&
        other.emailAddress == emailAddress &&
        other.provider == provider &&
        other.displayName == displayName &&
        other.isActive == isActive &&
        other.syncEnabled == syncEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, emailAddress, provider, displayName, isActive, syncEnabled);
  }

  @override
  String toString() {
    return 'EmailAccount{id: $id, emailAddress: $emailAddress, provider: ${provider.displayName}, isActive: $isActive}';
  }

  // Formatted tarihler
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
  }

  String get formattedLastSync {
    if (lastSync == null) return 'Henüz senkronize edilmedi';
    return DateFormat('dd.MM.yyyy HH:mm').format(lastSync!);
  }

  // Token'ın geçerli olup olmadığını kontrol et
  bool get isTokenValid {
    if (tokenExpires == null) return false;
    return DateTime.now().isBefore(tokenExpires!);
  }

  // Token'ın yenilenmesi gerekip gerekmediğini kontrol et (örn: 24 saat kala)
  bool get shouldRefreshToken {
    if (tokenExpires == null) return true;
    final timeUntilExpiry = tokenExpires!.difference(DateTime.now());
    return timeUntilExpiry.inHours < 24;
  }

  // Son senkronizasyonun ne kadar süre önce olduğunu hesapla
  Duration? get timeSinceLastSync {
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync!);
  }

  // Senkronizasyonun gerekli olup olmadığını kontrol et (örn: 15 dakikadan fazla geçtiyse)
  bool get needsSync {
    if (!syncEnabled || !isActive) return false;
    if (lastSync == null) return true;
    return timeSinceLastSync!.inMinutes > 15;
  }

  // Sağlayıcıya göre ikon
  String get providerIcon {
    switch (provider) {
      case EmailProvider.gmail:
        return '📧';
      case EmailProvider.outlook:
        return '🔵';
      case EmailProvider.yahoo:
        return '🟣';
    }
  }

  // Sağlayıcıya göre renk
  String get providerColor {
    switch (provider) {
      case EmailProvider.gmail:
        return '#EA4335';
      case EmailProvider.outlook:
        return '#0078D4';
      case EmailProvider.yahoo:
        return '#720E9E';
    }
  }
}