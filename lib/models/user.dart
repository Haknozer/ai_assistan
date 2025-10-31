import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int? id;
  final String email;
  final String name;
  @JsonKey(name: 'password_hash')
  final String? passwordHash;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'theme_preference')
  final String themePreference;
  final String language;

  const User({
    this.id,
    required this.email,
    required this.name,
    this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.themePreference = 'system',
    this.language = 'tr',
  });

  // Veritabanından gelen veri için constructor
  factory User.fromDatabase(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      name: map['name'] as String,
      passwordHash: map['password_hash'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as int) == 1,
      themePreference: map['theme_preference'] as String? ?? 'system',
      language: map['language'] as String? ?? 'tr',
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      if (passwordHash != null) 'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'theme_preference': themePreference,
      'language': language,
    };
  }

  // JSON serialization
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Copy with method
  User copyWith({
    int? id,
    String? email,
    String? name,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? themePreference,
    String? language,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      themePreference: themePreference ?? this.themePreference,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.isActive == isActive &&
        other.themePreference == themePreference &&
        other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, name, isActive, themePreference, language);
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, isActive: $isActive}';
  }

  // Formatted tarihleri almak için
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
  }
}