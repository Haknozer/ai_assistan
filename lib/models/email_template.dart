import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'email_template.g.dart';

@JsonSerializable()
class EmailTemplate {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String name;
  final String? subject;
  final String? body;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const EmailTemplate({
    this.id,
    required this.userId,
    required this.name,
    this.subject,
    this.body,
    this.isDefault = false,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Veritabanından gelen veri için constructor
  factory EmailTemplate.fromDatabase(Map<String, dynamic> map) {
    return EmailTemplate(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      subject: map['subject'] as String?,
      body: map['body'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      usageCount: map['usage_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'subject': subject,
      'body': body,
      'is_default': isDefault ? 1 : 0,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory EmailTemplate.fromJson(Map<String, dynamic> json) => _$EmailTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$EmailTemplateToJson(this);

  // Copy with method
  EmailTemplate copyWith({
    int? id,
    int? userId,
    String? name,
    String? subject,
    String? body,
    bool? isDefault,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      isDefault: isDefault ?? this.isDefault,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailTemplate &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.subject == subject &&
        other.body == body &&
        other.isDefault == isDefault &&
        other.usageCount == usageCount;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, name, subject, body, isDefault, usageCount);
  }

  @override
  String toString() {
    return 'EmailTemplate{id: $id, name: $name, usageCount: $usageCount, isDefault: $isDefault}';
  }

  // Formatted tarihler
  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
  }

  // Şablonun boş olup olmadığını kontrol et
  bool get hasSubject => subject != null && subject!.isNotEmpty;
  bool get hasBody => body != null && body!.isNotEmpty;
  bool get isEmpty => !hasSubject && !hasBody;

  // Şablonun kullanım sıklığını hesapla
  String get usageFrequency {
    if (usageCount == 0) return 'Henüz kullanılmadı';
    if (usageCount == 1) return '1 kez kullanıldı';
    return '$usageCount kez kullanıldı';
  }

  // Şablonun oluşturulmasından ne kadar zaman geçtiğini hesapla
  Duration get timeSinceCreated {
    return DateTime.now().difference(createdAt);
  }

  // Şablonun son güncellenmesinden ne kadar zaman geçtiğini hesapla
  Duration get timeSinceUpdated {
    return DateTime.now().difference(updatedAt);
  }

  // Göreceli zaman gösterimi
  String get relativeCreatedTime {
    final difference = timeSinceCreated;

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

  // Varsayılan şablon ise ikon
  String get statusIcon {
    return isDefault ? '⭐' : '📄';
  }

  // Kullanım sayısına göre renk kodu
  String get usageColor {
    if (usageCount == 0) {
      return '#9E9E9E'; // Grey
    } else if (usageCount <= 5) {
      return '#4CAF50'; // Green
    } else if (usageCount <= 15) {
      return '#FF9800'; // Orange
    } else {
      return '#F44336'; // Red
    }
  }

  // Şablonun kategorisini belirle (içeriğe göre)
  String get category {
    final lowerSubject = subject?.toLowerCase() ?? '';
    final lowerBody = body?.toLowerCase() ?? '';
    final content = '$lowerSubject $lowerBody';

    if (content.contains('toplantı') || content.contains('meeting')) {
      return 'Toplantı';
    } else if (content.contains('randevu') || content.contains('appointment')) {
      return 'Randevu';
    } else if (content.contains('teşekkür') || content.contains('thank')) {
      return 'Teşekkür';
    } else if (content.contains('bilgi') || content.contains('information')) {
      return 'Bilgilendirme';
    } else if (content.contains('hatırlat') || content.contains('reminder')) {
      return 'Hatırlatma';
    } else {
      return 'Genel';
    }
  }

  // Kategoriye göre ikon
  String get categoryIcon {
    switch (category) {
      case 'Toplantı':
        return '👥';
      case 'Randevu':
        return '📅';
      case 'Teşekkür':
        return '🙏';
      case 'Bilgilendirme':
        return 'ℹ️';
      case 'Hatırlatma':
        return '⏰';
      default:
        return '📄';
    }
  }
}