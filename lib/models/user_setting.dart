import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'user_setting.g.dart';

enum SettingCategory {
  general,
  notifications,
  email,
  calendar,
  privacy,
  ai;

  String get displayName {
    switch (this) {
      case SettingCategory.general:
        return 'Genel';
      case SettingCategory.notifications:
        return 'Bildirimler';
      case SettingCategory.email:
        return 'E-posta';
      case SettingCategory.calendar:
        return 'Takvim';
      case SettingCategory.privacy:
        return 'Gizlilik';
      case SettingCategory.ai:
        return 'Yapay Zeka';
    }
  }

  static SettingCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return SettingCategory.general;
      case 'notifications':
        return SettingCategory.notifications;
      case 'email':
        return SettingCategory.email;
      case 'calendar':
        return SettingCategory.calendar;
      case 'privacy':
        return SettingCategory.privacy;
      case 'ai':
        return SettingCategory.ai;
      default:
        return SettingCategory.general;
    }
  }
}

@JsonSerializable()
class UserSetting {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'setting_key')
  final String settingKey;
  @JsonKey(name: 'setting_value')
  final String? settingValue;
  final SettingCategory category;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UserSetting({
    this.id,
    required this.userId,
    required this.settingKey,
    this.settingValue,
    this.category = SettingCategory.general,
    required this.updatedAt,
  });

  // Veritabanından gelen veri için constructor
  factory UserSetting.fromDatabase(Map<String, dynamic> map) {
    return UserSetting(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      settingKey: map['setting_key'] as String,
      settingValue: map['setting_value'] as String?,
      category: SettingCategory.fromString(map['category'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'category': category.name,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory UserSetting.fromJson(Map<String, dynamic> json) => _$UserSettingFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingToJson(this);

  // Copy with method
  UserSetting copyWith({
    int? id,
    int? userId,
    String? settingKey,
    String? settingValue,
    SettingCategory? category,
    DateTime? updatedAt,
  }) {
    return UserSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSetting &&
        other.id == id &&
        other.userId == userId &&
        other.settingKey == settingKey &&
        other.settingValue == settingValue &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, settingKey, settingValue, category);
  }

  @override
  String toString() {
    return 'UserSetting{id: $id, settingKey: $settingKey, settingValue: $settingValue, category: ${category.displayName}}';
  }

  // Formatted tarih
  String get formattedUpdatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
  }

  // Değer tipleri için yardımcı metodlar
  bool getBoolValue() {
    return settingValue?.toLowerCase() == 'true';
  }

  int getIntValue() {
    return int.tryParse(settingValue ?? '0') ?? 0;
  }

  double getDoubleValue() {
    return double.tryParse(settingValue ?? '0.0') ?? 0.0;
  }

  String getStringValue() {
    return settingValue ?? '';
  }

  List<String> getListValue() {
    if (settingValue == null || settingValue!.isEmpty) return [];
    try {
      // JSON formatında ise parse et
      if (settingValue!.startsWith('[') && settingValue!.endsWith(']')) {
        return List<String>.from(
          settingValue!.replaceAll(RegExp(r'[\[\]" ]'), '').split(',')
        );
      }
      // Virgülle ayrılmış ise
      return settingValue!.split(',').map((e) => e.trim()).toList();
    } catch (e) {
      return [settingValue!];
    }
  }

  // Ayarın boş olup olmadığını kontrol et
  bool get isEmpty => settingValue == null || settingValue!.isEmpty;

  // Ayarın güncellenmesinden ne kadar zaman geçtiğini hesapla
  Duration get timeSinceUpdated {
    return DateTime.now().difference(updatedAt);
  }

  // Göreceli zaman gösterimi
  String get relativeUpdatedTime {
    final difference = timeSinceUpdated;

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // Kategoriye göre renk
  String get categoryColor {
    switch (category) {
      case SettingCategory.general:
        return '#2196F3'; // Blue
      case SettingCategory.notifications:
        return '#FF9800'; // Orange
      case SettingCategory.email:
        return '#4CAF50'; // Green
      case SettingCategory.calendar:
        return '#9C27B0'; // Purple
      case SettingCategory.privacy:
        return '#F44336'; // Red
      case SettingCategory.ai:
        return '#00BCD4'; // Cyan
    }
  }

  // Kategoriye göre ikon
  String get categoryIcon {
    switch (category) {
      case SettingCategory.general:
        return '⚙️';
      case SettingCategory.notifications:
        return '🔔';
      case SettingCategory.email:
        return '📧';
      case SettingCategory.calendar:
        return '📅';
      case SettingCategory.privacy:
        return '🔒';
      case SettingCategory.ai:
        return '🤖';
    }
  }

  // Değer tipine göre gösterim
  String get displayValue {
    if (isEmpty) return 'Ayarlanmamış';

    // Boolean değerler için
    if (settingValue?.toLowerCase() == 'true') return 'Evet';
    if (settingValue?.toLowerCase() == 'false') return 'Hayır';

    // Liste değerler için
    if (settingValue!.startsWith('[')) {
      final list = getListValue();
      return '${list.length} öğe';
    }

    // Uzun metinler için
    if (settingValue!.length > 50) {
      return '${settingValue!.substring(0, 50)}...';
    }

    return settingValue!;
  }

  // Örnek ayarlar için statik factory metodlar
  static UserSetting themeSetting({required int userId, required String theme}) {
    return UserSetting(
      userId: userId,
      settingKey: 'theme',
      settingValue: theme,
      category: SettingCategory.general,
      updatedAt: DateTime.now(),
    );
  }

  static UserSetting languageSetting({required int userId, required String language}) {
    return UserSetting(
      userId: userId,
      settingKey: 'language',
      settingValue: language,
      category: SettingCategory.general,
      updatedAt: DateTime.now(),
    );
  }

  static UserSetting emailNotificationSetting({required int userId, required bool enabled}) {
    return UserSetting(
      userId: userId,
      settingKey: 'email_notifications',
      settingValue: enabled.toString(),
      category: SettingCategory.notifications,
      updatedAt: DateTime.now(),
    );
  }

  static UserSetting autoSyncSetting({required int userId, required bool enabled}) {
    return UserSetting(
      userId: userId,
      settingKey: 'auto_sync',
      settingValue: enabled.toString(),
      category: SettingCategory.email,
      updatedAt: DateTime.now(),
    );
  }

  static UserSetting aiSummarySetting({required int userId, required bool enabled}) {
    return UserSetting(
      userId: userId,
      settingKey: 'ai_summary',
      settingValue: enabled.toString(),
      category: SettingCategory.ai,
      updatedAt: DateTime.now(),
    );
  }
}