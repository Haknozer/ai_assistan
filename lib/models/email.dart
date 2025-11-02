import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'email.g.dart';

enum EmailImportance {
  normal,
  important,
  urgent;

  String get displayName {
    switch (this) {
      case EmailImportance.normal:
        return 'Normal';
      case EmailImportance.important:
        return 'Önemli';
      case EmailImportance.urgent:
        return 'Acil';
    }
  }

  static EmailImportance fromString(String importance) {
    switch (importance.toLowerCase()) {
      case 'normal':
        return EmailImportance.normal;
      case 'important':
        return EmailImportance.important;
      case 'urgent':
        return EmailImportance.urgent;
      default:
        return EmailImportance.normal;
    }
  }

  static EmailImportance fromInt(int? importance) {
    switch (importance) {
      case 1:
        return EmailImportance.important;
      case 2:
        return EmailImportance.urgent;
      default:
        return EmailImportance.normal;
    }
  }
}

enum EmailStatus {
  draft,
  sent,
  received,
  read,
  unread;

  String get displayName {
    switch (this) {
      case EmailStatus.draft:
        return 'Taslak';
      case EmailStatus.sent:
        return 'Gönderildi';
      case EmailStatus.received:
        return 'Alındı';
      case EmailStatus.read:
        return 'Okundu';
      case EmailStatus.unread:
        return 'Okunmamış';
    }
  }

  static EmailStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return EmailStatus.draft;
      case 'sent':
        return EmailStatus.sent;
      case 'received':
        return EmailStatus.received;
      case 'read':
        return EmailStatus.read;
      case 'unread':
        return EmailStatus.unread;
      default:
        return EmailStatus.unread;
    }
  }

  static EmailStatus fromInt(int? status) {
    switch (status) {
      case 0:
        return EmailStatus.draft;
      case 1:
        return EmailStatus.sent;
      case 2:
        return EmailStatus.received;
      case 3:
        return EmailStatus.read;
      default:
        return EmailStatus.unread;
    }
  }
}

enum EmailFolder {
  inbox,
  sent,
  drafts,
  trash,
  spam,
  important;

  String get displayName {
    switch (this) {
      case EmailFolder.inbox:
        return 'Gelen Kutusu';
      case EmailFolder.sent:
        return 'Gönderilen';
      case EmailFolder.drafts:
        return 'Taslaklar';
      case EmailFolder.trash:
        return 'Çöp';
      case EmailFolder.spam:
        return 'Spam';
      case EmailFolder.important:
        return 'Önemli';
    }
  }

  static EmailFolder fromString(String folder) {
    switch (folder.toLowerCase()) {
      case 'inbox':
        return EmailFolder.inbox;
      case 'sent':
        return EmailFolder.sent;
      case 'drafts':
        return EmailFolder.drafts;
      case 'trash':
        return EmailFolder.trash;
      case 'spam':
        return EmailFolder.spam;
      case 'important':
        return EmailFolder.important;
      default:
        return EmailFolder.inbox;
    }
  }
}

@JsonSerializable()
class Email {
  final int? id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'account_id')
  final int accountId;
  @JsonKey(name: 'message_id')
  final String? messageId;
  @JsonKey(name: 'thread_id')
  final String? threadId;
  @JsonKey(name: 'subject')
  final String subject;
  @JsonKey(name: 'from_email')
  final String fromEmail;
  @JsonKey(name: 'from_name')
  final String? fromName;
  @JsonKey(name: 'to_emails')
  final List<String> toEmails;
  @JsonKey(name: 'cc_emails')
  final List<String>? ccEmails;
  @JsonKey(name: 'bcc_emails')
  final List<String>? bccEmails;
  @JsonKey(name: 'plain_text')
  final String? plainText;
  @JsonKey(name: 'html_content')
  final String? htmlContent;
  @JsonKey(name: 'attachments')
  final List<EmailAttachment>? attachments;
  @JsonKey(name: 'received_date')
  final DateTime? receivedDate;
  @JsonKey(name: 'sent_date')
  final DateTime? sentDate;
  @JsonKey(name: 'email_status')
  final EmailStatus status;
  @JsonKey(name: 'email_importance')
  final EmailImportance importance;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'is_starred')
  final bool isStarred;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @JsonKey(name: 'is_spam')
  final bool isSpam;
  @JsonKey(name: 'folder')
  final EmailFolder folder;
  @JsonKey(name: 'labels')
  final List<String>? labels;
  @JsonKey(name: 'size_bytes')
  final int? sizeBytes;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Email({
    this.id,
    required this.userId,
    required this.accountId,
    this.messageId,
    this.threadId,
    required this.subject,
    required this.fromEmail,
    this.fromName,
    required this.toEmails,
    this.ccEmails,
    this.bccEmails,
    this.plainText,
    this.htmlContent,
    this.attachments,
    this.receivedDate,
    this.sentDate,
    this.status = EmailStatus.received,
    this.importance = EmailImportance.normal,
    this.isRead = false,
    this.isStarred = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.isSpam = false,
    this.folder = EmailFolder.inbox,
    this.labels,
    this.sizeBytes,
    this.externalId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Veritabanından gelen veri için constructor
  factory Email.fromDatabase(Map<String, dynamic> map) {
    return Email(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      accountId: map['account_id'] as int,
      messageId: map['message_id'] as String?,
      threadId: map['thread_id'] as String?,
      subject: map['subject'] as String,
      fromEmail: map['from_email'] as String,
      fromName: map['from_name'] as String?,
      toEmails: map['to_emails'] != null ? List<String>.from(map['to_emails'] as List) : [],
      ccEmails: map['cc_emails'] != null ? List<String>.from(map['cc_emails'] as List) : null,
      bccEmails: map['bcc_emails'] != null ? List<String>.from(map['bcc_emails'] as List) : null,
      plainText: map['plain_text'] as String?,
      htmlContent: map['html_content'] as String?,
      attachments: map['attachments'] != null
          ? (map['attachments'] as List).map((a) => EmailAttachment.fromJson(a as Map<String, dynamic>)).toList()
          : null,
      receivedDate: map['received_date'] != null ? DateTime.parse(map['received_date'] as String) : null,
      sentDate: map['sent_date'] != null ? DateTime.parse(map['sent_date'] as String) : null,
      status: EmailStatus.fromInt(map['email_status'] as int?),
      importance: EmailImportance.fromInt(map['email_importance'] as int?),
      isRead: (map['is_read'] as int?) == 1,
      isStarred: (map['is_starred'] as int?) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
      isSpam: (map['is_spam'] as int?) == 1,
      folder: EmailFolder.fromString(map['folder'] as String? ?? 'inbox'),
      labels: map['labels'] != null ? List<String>.from(map['labels'] as List) : null,
      sizeBytes: map['size_bytes'] as int?,
      externalId: map['external_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Veritabanına gönderilecek formata çevirme
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'account_id': accountId,
      'message_id': messageId,
      'thread_id': threadId,
      'subject': subject,
      'from_email': fromEmail,
      'from_name': fromName,
      'to_emails': toEmails,
      'cc_emails': ccEmails,
      'bcc_emails': bccEmails,
      'plain_text': plainText,
      'html_content': htmlContent,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'received_date': receivedDate?.toIso8601String(),
      'sent_date': sentDate?.toIso8601String(),
      'email_status': status.index,
      'email_importance': importance.index,
      'is_read': isRead ? 1 : 0,
      'is_starred': isStarred ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'is_spam': isSpam ? 1 : 0,
      'folder': folder.name,
      'labels': labels,
      'size_bytes': sizeBytes,
      'external_id': externalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON serialization
  factory Email.fromJson(Map<String, dynamic> json) => _$EmailFromJson(json);
  Map<String, dynamic> toJson() => _$EmailToJson(this);

  // Copy with method
  Email copyWith({
    int? id,
    int? userId,
    int? accountId,
    String? messageId,
    String? threadId,
    String? subject,
    String? fromEmail,
    String? fromName,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? plainText,
    String? htmlContent,
    List<EmailAttachment>? attachments,
    DateTime? receivedDate,
    DateTime? sentDate,
    EmailStatus? status,
    EmailImportance? importance,
    bool? isRead,
    bool? isStarred,
    bool? isArchived,
    bool? isDeleted,
    bool? isSpam,
    EmailFolder? folder,
    List<String>? labels,
    int? sizeBytes,
    String? externalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Email(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      messageId: messageId ?? this.messageId,
      threadId: threadId ?? this.threadId,
      subject: subject ?? this.subject,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      toEmails: toEmails ?? this.toEmails,
      ccEmails: ccEmails ?? this.ccEmails,
      bccEmails: bccEmails ?? this.bccEmails,
      plainText: plainText ?? this.plainText,
      htmlContent: htmlContent ?? this.htmlContent,
      attachments: attachments ?? this.attachments,
      receivedDate: receivedDate ?? this.receivedDate,
      sentDate: sentDate ?? this.sentDate,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      isSpam: isSpam ?? this.isSpam,
      folder: folder ?? this.folder,
      labels: labels ?? this.labels,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Email &&
        other.id == id &&
        other.userId == userId &&
        other.accountId == accountId &&
        other.messageId == messageId &&
        other.threadId == threadId &&
        other.subject == subject &&
        other.fromEmail == fromEmail &&
        other.fromName == fromName &&
        other.toEmails == toEmails &&
        other.ccEmails?.toString() == ccEmails?.toString() &&
        other.bccEmails?.toString() == bccEmails?.toString() &&
        other.plainText == plainText &&
        other.htmlContent == htmlContent &&
        other.receivedDate == receivedDate &&
        other.sentDate == sentDate &&
        other.status == status &&
        other.importance == importance &&
        other.isRead == isRead &&
        other.isStarred == isStarred &&
        other.isArchived == isArchived &&
        other.isDeleted == isDeleted &&
        other.isSpam == isSpam &&
        other.folder == folder &&
        other.labels?.toString() == labels?.toString() &&
        other.sizeBytes == sizeBytes &&
        other.externalId == externalId;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id, userId, accountId, messageId, threadId, subject, fromEmail, fromName,
      toEmails, ccEmails, bccEmails, plainText, htmlContent,
      receivedDate, sentDate, status, importance, isRead, isStarred,
      isArchived, isDeleted, isSpam, folder, labels, sizeBytes, externalId,
      createdAt, updatedAt
    ]);
  }

  @override
  String toString() {
    return 'Email{id: $id, subject: $subject, from: $fromEmail, status: $status}';
  }

  // Formatted tarihler
  String get formattedReceivedDate {
    if (receivedDate == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(receivedDate!);
  }

  String get formattedSentDate {
    if (sentDate == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(sentDate!);
  }

  String get formattedDate {
    return formattedReceivedDate.isNotEmpty ? formattedReceivedDate : formattedSentDate;
  }

  String get formattedTime {
    final date = receivedDate ?? sentDate;
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  // İçerik özeti (plain text veya html'den)
  String get contentPreview {
    String content = plainText ?? htmlContent ?? '';

    if (content.isEmpty) return '';

    // HTML etiketlerini temizle
    content = content.replaceAll(RegExp(r'<[^>]*>'), '');

    // Satır sonu ve fazla boşlukları temizle
    content = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    // İlk 100 karakter
    if (content.length > 100) {
      content = '${content.substring(0, 100)}...';
    }

    return content;
  }

  // Alıcı bilgisi
  String get fromDisplayName {
    if (fromName != null && fromName!.isNotEmpty) {
      return '$fromName <$fromEmail>';
    }
    return fromEmail;
  }

  // Tüm alıcılar
  List<String> get allRecipients {
    final recipients = <String>[];
    recipients.addAll(toEmails);
    if (ccEmails != null) recipients.addAll(ccEmails!);
    if (bccEmails != null) recipients.addAll(bccEmails!);
    return recipients;
  }

  // Ekli olup olmaduğu
  bool get hasAttachments {
    return attachments != null && attachments!.isNotEmpty;
  }

  // Eklerin toplam boyutu
  int get totalAttachmentSize {
    if (!hasAttachments) return 0;
    return attachments!.fold(0, (sum, attachment) => sum + (attachment.sizeBytes ?? 0));
  }

  // Ek sayısı
  int get attachmentCount {
    if (!hasAttachments) return 0;
    return attachments!.length;
  }

  // Spam filtresi
  bool get shouldBeInSpam {
    return isSpam ||
           (importance == EmailImportance.urgent && !isRead) ||
           (subject.toLowerCase().contains('spam') || subject.toLowerCase().contains('winning')) ||
           (fromEmail.toLowerCase().contains('noreply') || fromEmail.toLowerCase().contains('marketing'));
  }

  // Okunmamış olup olmaduğu
  bool get isUnread {
    return !isRead && status == EmailStatus.received;
  }

  // Yeni gelen mi
  bool get isNew {
    if (receivedDate == null) return false;
    final now = DateTime.now();
    final timeSinceReceived = now.difference(receivedDate!);
    return timeSinceReceived.inHours < 24 && isUnread;
  }

  // Gecikmiş mi
  bool get isOld {
    if (receivedDate == null) return false;
    final now = DateTime.now();
    final timeSinceReceived = now.difference(receivedDate!);
    return timeSinceReceived.inDays > 30;
  }

  // Önemli olup olmaduğu
  bool get isImportant {
    return importance == EmailImportance.important || importance == EmailImportance.urgent || isStarred;
  }

  // Renk ve ikon bilgileri
  String get statusIcon {
    switch (status) {
      case EmailStatus.draft:
        return '✏️';
      case EmailStatus.sent:
        return '📤';
      case EmailStatus.received:
        return '📥';
      case EmailStatus.read:
        return '📖';
      case EmailStatus.unread:
        return '📬';
    }
  }

  String get statusColor {
    switch (status) {
      case EmailStatus.draft:
        return '#757575'; // Grey
      case EmailStatus.sent:
        return '#2196F3'; // Blue
      case EmailStatus.received:
        return '#4CAF50'; // Green
      case EmailStatus.read:
        return '#607D8B'; // Blue Grey
      case EmailStatus.unread:
        return '#1976D2'; // Primary Blue
    }
  }

  String get importanceIcon {
    switch (importance) {
      case EmailImportance.normal:
        return '';
      case EmailImportance.important:
        return '⭐';
      case EmailImportance.urgent:
        return '⚠️';
    }
  }

  String get importanceColor {
    switch (importance) {
      case EmailImportance.normal:
        return 'transparent';
      case EmailImportance.important:
        return '#FFA500'; // Amber
      case EmailImportance.urgent:
        return '#F44336'; // Red
    }
  }

  // Folder ikonları
  String get folderIcon {
    switch (folder) {
      case EmailFolder.inbox:
        return '📥';
      case EmailFolder.sent:
        return '📤';
      case EmailFolder.drafts:
        return '📝';
      case EmailFolder.trash:
        return '🗑️';
      case EmailFolder.spam:
        return '🚫';
      case EmailFolder.important:
        return '⭐';
    }
  }

  String get folderColor {
    switch (folder) {
      case EmailFolder.inbox:
        return '#1976D2';
      case EmailFolder.sent:
        return '#2196F3';
      case EmailFolder.drafts:
        return '#607D8B';
      case EmailFolder.trash:
        return '#F44336';
      case EmailFolder.spam:
        return '#FF5722';
      case EmailFolder.important:
        return '#FFA500';
    }
  }
}

// Email attachment modeli
@JsonSerializable()
class EmailAttachment {
  final int? id;
  @JsonKey(name: 'email_id')
  final int emailId;
  @JsonKey(name: 'filename')
  final String filename;
  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'size_bytes')
  final int? sizeBytes;
  @JsonKey(name: 'storage_path')
  final String? storagePath;
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @JsonKey(name: 'is_downloaded')
  final bool isDownloaded;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const EmailAttachment({
    this.id,
    required this.emailId,
    required this.filename,
    required this.contentType,
    this.sizeBytes,
    this.storagePath,
    this.downloadUrl,
    this.isDownloaded = false,
    required this.createdAt,
  });

  // JSON serialization
  factory EmailAttachment.fromJson(Map<String, dynamic> json) => _$EmailAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$EmailAttachmentToJson(this);

  // Copy with method
  EmailAttachment copyWith({
    int? id,
    int? emailId,
    String? filename,
    String? contentType,
    int? sizeBytes,
    String? storagePath,
    String? downloadUrl,
    bool? isDownloaded,
    DateTime? createdAt,
  }) {
    return EmailAttachment(
      id: id ?? this.id,
      emailId: emailId ?? this.emailId,
      filename: filename ?? this.filename,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Dosya uzantısı ikonu
  String get fileIcon {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📄';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return '🎬';
      case 'zip':
      case 'rar':
      case '7z':
        return '🗜️';
      case 'txt':
      case 'md':
        return '📄';
      default:
        return '📎';
    }
  }

  // Formatted dosya boyutu
  String get formattedSize {
    if (sizeBytes == null) return 'Bilinmiyor';

    final bytes = sizeBytes!;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}