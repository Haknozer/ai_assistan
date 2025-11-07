// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Email _$EmailFromJson(Map<String, dynamic> json) => Email(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      accountId: (json['account_id'] as num).toInt(),
      messageId: json['message_id'] as String?,
      threadId: json['thread_id'] as String?,
      subject: json['subject'] as String,
      fromEmail: json['from_email'] as String,
      fromName: json['from_name'] as String?,
      toEmails:
          (json['to_emails'] as List<dynamic>).map((e) => e as String).toList(),
      ccEmails: (json['cc_emails'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bccEmails: (json['bcc_emails'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      plainText: json['plain_text'] as String?,
      htmlContent: json['html_content'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => EmailAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      receivedDate: json['received_date'] == null
          ? null
          : DateTime.parse(json['received_date'] as String),
      sentDate: json['sent_date'] == null
          ? null
          : DateTime.parse(json['sent_date'] as String),
      status: $enumDecodeNullable(_$EmailStatusEnumMap, json['email_status']) ??
          EmailStatus.received,
      importance: $enumDecodeNullable(
              _$EmailImportanceEnumMap, json['email_importance']) ??
          EmailImportance.normal,
      isRead: json['is_read'] as bool? ?? false,
      isStarred: json['is_starred'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isSpam: json['is_spam'] as bool? ?? false,
      folder: $enumDecodeNullable(_$EmailFolderEnumMap, json['folder']) ??
          EmailFolder.inbox,
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      externalId: json['external_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EmailToJson(Email instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'account_id': instance.accountId,
      'message_id': instance.messageId,
      'thread_id': instance.threadId,
      'subject': instance.subject,
      'from_email': instance.fromEmail,
      'from_name': instance.fromName,
      'to_emails': instance.toEmails,
      'cc_emails': instance.ccEmails,
      'bcc_emails': instance.bccEmails,
      'plain_text': instance.plainText,
      'html_content': instance.htmlContent,
      'attachments': instance.attachments,
      'received_date': instance.receivedDate?.toIso8601String(),
      'sent_date': instance.sentDate?.toIso8601String(),
      'email_status': _$EmailStatusEnumMap[instance.status]!,
      'email_importance': _$EmailImportanceEnumMap[instance.importance]!,
      'is_read': instance.isRead,
      'is_starred': instance.isStarred,
      'is_archived': instance.isArchived,
      'is_deleted': instance.isDeleted,
      'is_spam': instance.isSpam,
      'folder': _$EmailFolderEnumMap[instance.folder]!,
      'labels': instance.labels,
      'size_bytes': instance.sizeBytes,
      'external_id': instance.externalId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$EmailStatusEnumMap = {
  EmailStatus.draft: 'draft',
  EmailStatus.sent: 'sent',
  EmailStatus.received: 'received',
  EmailStatus.read: 'read',
  EmailStatus.unread: 'unread',
};

const _$EmailImportanceEnumMap = {
  EmailImportance.normal: 'normal',
  EmailImportance.important: 'important',
  EmailImportance.urgent: 'urgent',
};

const _$EmailFolderEnumMap = {
  EmailFolder.inbox: 'inbox',
  EmailFolder.sent: 'sent',
  EmailFolder.drafts: 'drafts',
  EmailFolder.trash: 'trash',
  EmailFolder.spam: 'spam',
  EmailFolder.important: 'important',
};

EmailAttachment _$EmailAttachmentFromJson(Map<String, dynamic> json) =>
    EmailAttachment(
      id: (json['id'] as num?)?.toInt(),
      emailId: (json['email_id'] as num).toInt(),
      filename: json['filename'] as String,
      contentType: json['content_type'] as String,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      storagePath: json['storage_path'] as String?,
      downloadUrl: json['download_url'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$EmailAttachmentToJson(EmailAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email_id': instance.emailId,
      'filename': instance.filename,
      'content_type': instance.contentType,
      'size_bytes': instance.sizeBytes,
      'storage_path': instance.storagePath,
      'download_url': instance.downloadUrl,
      'is_downloaded': instance.isDownloaded,
      'created_at': instance.createdAt.toIso8601String(),
    };
