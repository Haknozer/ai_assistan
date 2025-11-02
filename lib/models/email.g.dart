// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Email _$EmailFromJson(Map<String, dynamic> json) => Email(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      accountId: json['accountId'] as int,
      messageId: json['messageId'] as String?,
      threadId: json['threadId'] as String?,
      subject: json['subject'] as String,
      fromEmail: json['fromEmail'] as String,
      fromName: json['fromName'] as String?,
      toEmails: (json['toEmails'] as List<dynamic>).map((e) => e as String).toList(),
      ccEmails: (json['ccEmails'] as List<dynamic>?)?.map((e) => e as String).toList(),
      bccEmails: (json['bccEmails'] as List<dynamic>?)?.map((e) => e as String).toList(),
      plainText: json['plainText'] as String?,
      htmlContent: json['htmlContent'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => EmailAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      receivedDate: json['receivedDate'] == null ? null : DateTime.parse(json['receivedDate'] as String),
      sentDate: json['sentDate'] == null ? null : DateTime.parse(json['sentDate'] as String),
      status: $enumDecode(_$EmailStatusEnumMap, json['status']),
      importance: $enumDecode(_$EmailImportanceEnumMap, json['importance']),
      isRead: json['isRead'] as bool,
      isStarred: json['isStarred'] as bool,
      isArchived: json['isArchived'] as bool,
      isDeleted: json['isDeleted'] as bool,
      isSpam: json['isSpam'] as bool,
      folder: $enumDecode(_$EmailFolderEnumMap, json['folder']),
      labels: (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sizeBytes: json['sizeBytes'] as int?,
      externalId: json['externalId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EmailToJson(Email instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'accountId': instance.accountId,
      'messageId': instance.messageId,
      'threadId': instance.threadId,
      'subject': instance.subject,
      'fromEmail': instance.fromEmail,
      'fromName': instance.fromName,
      'toEmails': instance.toEmails,
      'ccEmails': instance.ccEmails,
      'bccEmails': instance.bccEmails,
      'plainText': instance.plainText,
      'htmlContent': instance.htmlContent,
      'attachments': instance.attachments,
      'receivedDate': instance.receivedDate?.toIso8601String(),
      'sentDate': instance.sentDate?.toIso8601String(),
      'status': _$EmailStatusEnumMap[instance.status]!,
      'importance': _$EmailImportanceEnumMap[instance.importance]!,
      'isRead': instance.isRead,
      'isStarred': instance.isStarred,
      'isArchived': instance.isArchived,
      'isDeleted': instance.isDeleted,
      'isSpam': instance.isSpam,
      'folder': _$EmailFolderEnumMap[instance.folder]!,
      'labels': instance.labels,
      'sizeBytes': instance.sizeBytes,
      'externalId': instance.externalId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
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

EmailAttachment _$EmailAttachmentFromJson(Map<String, dynamic> json) => EmailAttachment(
      id: json['id'] as int?,
      emailId: json['emailId'] as int,
      filename: json['filename'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: json['sizeBytes'] as int?,
      storagePath: json['storagePath'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      isDownloaded: json['isDownloaded'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EmailAttachmentToJson(EmailAttachment instance) => <String, dynamic>{
      'id': instance.id,
      'emailId': instance.emailId,
      'filename': instance.filename,
      'contentType': instance.contentType,
      'sizeBytes': instance.sizeBytes,
      'storagePath': instance.storagePath,
      'downloadUrl': instance.downloadUrl,
      'isDownloaded': instance.isDownloaded,
      'createdAt': instance.createdAt.toIso8601String(),
    };
