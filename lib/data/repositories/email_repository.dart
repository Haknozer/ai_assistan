import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:ai_asisstan/core/database/database_service.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/services/email_service.dart';

/// Email verilerini API ve veritabanı arasında senkronize eden repository
class EmailRepository {
  final EmailService _emailService;
  final DatabaseService _databaseService;

  EmailRepository({
    EmailService? emailService,
    DatabaseService? databaseService,
  })  : _emailService = emailService ?? EmailService(),
        _databaseService = databaseService ?? DatabaseService.instance;

  /// Email listesini getir (cache'den veya API'den)
  /// [forceRefresh] true ise cache'i atlayıp API'den çeker
  Future<List<Email>> getEmails({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
    bool forceRefresh = false,
  }) async {
    final db = await _databaseService.database;

    // Önce cache'den kontrol et (forceRefresh değilse)
    if (!forceRefresh) {
      try {
        final cachedEmails = await _getCachedEmails(
          db,
          accountId: accountId,
          folder: folder,
          limit: limit,
          offset: offset,
        );
        if (cachedEmails.isNotEmpty) {
          return cachedEmails;
        }
      } catch (e) {
        // Cache hatası varsa API'den çek
      }
    }

    // API'den çek
    try {
      final emails = await _emailService.getEmails(
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
        accessToken: accessToken,
      );

      // Cache'e kaydet
      await _saveEmailsToCache(db, emails);

      return emails;
    } on NetworkException {
      // Network hatası varsa cache'den döndür
      final cachedEmails = await _getCachedEmails(
        db,
        accountId: accountId,
        folder: folder,
        limit: limit,
        offset: offset,
      );
      return cachedEmails;
    } catch (e) {
      // Diğer hatalar için cache'den döndür
      try {
        return await _getCachedEmails(
          db,
          accountId: accountId,
          folder: folder,
          limit: limit,
          offset: offset,
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Tek email detayını getir
  Future<Email?> getEmailById(int emailId, {String? accessToken, bool forceRefresh = false}) async {
    final db = await _databaseService.database;

    // Cache'den kontrol et
    if (!forceRefresh) {
      final cachedEmail = await _getCachedEmailById(db, emailId);
      if (cachedEmail != null) {
        return cachedEmail;
      }
    }

    // API'den çek
    try {
      final email = await _emailService.getEmailById(emailId, accessToken: accessToken);
      await _saveEmailToCache(db, email);
      return email;
    } on NotFoundException {
      // Cache'den de sil
      await _deleteEmailFromCache(db, emailId);
      rethrow;
    } catch (e) {
      // Hata varsa cache'den döndür
      return await _getCachedEmailById(db, emailId);
    }
  }

  /// Email gönder
  Future<Email> sendEmail({
    required int accountId,
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
    EmailImportance importance = EmailImportance.normal,
    String? accessToken,
  }) async {
    final email = await _emailService.sendEmail(
      accountId: accountId,
      toEmails: toEmails,
      subject: subject,
      plainText: plainText,
      htmlContent: htmlContent,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      importance: importance,
      accessToken: accessToken,
    );

    // Cache'e kaydet
    final db = await _databaseService.database;
    await _saveEmailToCache(db, email);

    return email;
  }

  /// Email'i okundu olarak işaretle
  Future<Email> markAsRead(int emailId, {String? accessToken}) async {
    final email = await _emailService.markAsRead(emailId, accessToken: accessToken);
    
    // Cache'i güncelle
    final db = await _databaseService.database;
    await _updateEmailInCache(db, email);

    return email;
  }

  /// Email'i okunmamış olarak işaretle
  Future<Email> markAsUnread(int emailId, {String? accessToken}) async {
    final email = await _emailService.markAsUnread(emailId, accessToken: accessToken);
    
    // Cache'i güncelle
    final db = await _databaseService.database;
    await _updateEmailInCache(db, email);

    return email;
  }

  /// Email'i önemli olarak işaretle/kaldır
  Future<Email> toggleImportant(int emailId, bool isImportant, {String? accessToken}) async {
    final email = await _emailService.toggleImportant(emailId, isImportant, accessToken: accessToken);
    
    // Cache'i güncelle
    final db = await _databaseService.database;
    await _updateEmailInCache(db, email);

    return email;
  }

  /// Email sil
  Future<void> deleteEmail(int emailId, {String? accessToken}) async {
    await _emailService.deleteEmail(emailId, accessToken: accessToken);
    
    // Cache'den sil
    final db = await _databaseService.database;
    await _deleteEmailFromCache(db, emailId);
  }

  /// Email ara
  Future<List<Email>> searchEmails({
    required String query,
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) async {
    return await _emailService.searchEmails(
      query: query,
      accountId: accountId,
      folder: folder,
      limit: limit,
      offset: offset,
      accessToken: accessToken,
    );
  }

  /// Email taslağı kaydet
  Future<Email> saveDraft({
    required int accountId,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    int? draftId,
    String? accessToken,
  }) async {
    final email = await _emailService.saveDraft(
      accountId: accountId,
      subject: subject,
      plainText: plainText,
      htmlContent: htmlContent,
      toEmails: toEmails,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      draftId: draftId,
      accessToken: accessToken,
    );

    // Cache'e kaydet
    final db = await _databaseService.database;
    await _saveEmailToCache(db, email);

    return email;
  }

  // Cache metodları

  Future<List<Email>> _getCachedEmails(
    Database db, {
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
  }) async {
    var query = 'SELECT * FROM emails WHERE is_deleted = 0';
    final whereArgs = <dynamic>[];

    if (accountId != null) {
      query += ' AND account_id = ?';
      whereArgs.add(accountId);
    }

    if (folder != null) {
      query += ' AND folder = ?';
      whereArgs.add(folder);
    }

    query += ' ORDER BY created_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      whereArgs.add(limit);
    }

    if (offset != null) {
      query += ' OFFSET ?';
      whereArgs.add(offset);
    }

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((map) => _emailFromDatabaseMap(map)).toList();
  }

  Future<Email?> _getCachedEmailById(Database db, int emailId) async {
    final maps = await db.query(
      'emails',
      where: 'id = ?',
      whereArgs: [emailId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _emailFromDatabaseMap(maps.first);
  }

  Future<void> _saveEmailsToCache(Database db, List<Email> emails) async {
    await db.transaction((txn) async {
      for (final email in emails) {
        await _saveEmailToCacheInTransaction(txn, email);
      }
    });
  }

  Future<void> _saveEmailToCache(Database db, Email email) async {
    await db.transaction((txn) async {
      await _saveEmailToCacheInTransaction(txn, email);
    });
  }

  Future<void> _saveEmailToCacheInTransaction(dynamic txn, Email email) async {
    final data = email.toDatabase();
    
    // JSON array'leri string'e çevir
    if (data['to_emails'] is List) {
      data['to_emails'] = jsonEncode(data['to_emails']);
    }
    if (data['cc_emails'] is List) {
      data['cc_emails'] = jsonEncode(data['cc_emails']);
    }
    if (data['bcc_emails'] is List) {
      data['bcc_emails'] = jsonEncode(data['bcc_emails']);
    }
    if (data['attachments'] is List) {
      data['attachments'] = jsonEncode(data['attachments']);
    }
    if (data['labels'] is List) {
      data['labels'] = jsonEncode(data['labels']);
    }

    // Var mı kontrol et
    if (email.id != null) {
      final existing = await txn.query(
        'emails',
        where: 'id = ?',
        whereArgs: [email.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.update('emails', data, where: 'id = ?', whereArgs: [email.id]);
      } else {
        await txn.insert('emails', data);
      }
    } else if (email.externalId != null) {
      final existing = await txn.query(
        'emails',
        where: 'external_id = ?',
        whereArgs: [email.externalId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.update('emails', data, where: 'external_id = ?', whereArgs: [email.externalId]);
      } else {
        await txn.insert('emails', data);
      }
    } else {
      await txn.insert('emails', data);
    }
  }

  Future<void> _updateEmailInCache(Database db, Email email) async {
    await _saveEmailToCache(db, email);
  }

  Future<void> _deleteEmailFromCache(Database db, int emailId) async {
    await db.delete('emails', where: 'id = ?', whereArgs: [emailId]);
  }

  Email _emailFromDatabaseMap(Map<String, dynamic> map) {
    // JSON string'leri parse et
    if (map['to_emails'] is String) {
      map['to_emails'] = jsonDecode(map['to_emails'] as String);
    }
    if (map['cc_emails'] is String) {
      map['cc_emails'] = jsonDecode(map['cc_emails'] as String);
    }
    if (map['bcc_emails'] is String) {
      map['bcc_emails'] = jsonDecode(map['bcc_emails'] as String);
    }
    if (map['attachments'] is String) {
      final attachmentsJson = jsonDecode(map['attachments'] as String) as List;
      map['attachments'] = attachmentsJson.map((a) => a as Map<String, dynamic>).toList();
    }
    if (map['labels'] is String) {
      map['labels'] = jsonDecode(map['labels'] as String);
    }

    return Email.fromDatabase(map);
  }
}

