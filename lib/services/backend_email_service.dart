import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/api/api_exceptions.dart';

/// Backend email servisi - Outlook email'lerini backend'den çeker
class BackendEmailService {
  final String baseUrl;

  BackendEmailService({
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Outlook email'lerini backend'den çek
  ///
  /// [accessToken] - Microsoft Graph API access token
  /// [category] - Email kategorisi filtresi (null = tüm kategorilerden çek): 'inbox', 'sent', 'spam', 'drafts'
  /// [limit] - Kaç email getirilecek (max 100, kategori null ise tüm klasörlerden)
  Future<BackendEmailResponse> fetchOutlookEmails({
    required String accessToken,
    String? category,
    int limit = 50,
  }) async {
    try {
      // URL oluştur
      final url = Uri.parse('$baseUrl/api/emails/outlook').replace(
        queryParameters: {
          if (category != null) 'category': category,
          'limit': limit.toString(),
        },
      );

      debugPrint('📧 Backend\'e email isteği gönderiliyor...');
      debugPrint('   URL: $url');
      debugPrint('   Category: ${category ?? "all"}');
      debugPrint('   Limit: $limit');

      // Authorization header ile istek gönder
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw NetworkException(
            message: 'Backend isteği zaman aşımına uğradı',
          );
        },
      );

      debugPrint('📧 Backend yanıtı: Status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmailResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
          message: 'Access token geçersiz veya süresi dolmuş. Lütfen tekrar giriş yapın.',
        );
      } else if (response.statusCode == 403) {
        throw ApiException(
          message: 'Email okuma yetkisi yok. Lütfen izinleri kontrol edin.',
        );
      } else {
        final errorBody = response.body;
        debugPrint('❌ Backend hatası: $errorBody');
        throw ApiException(
          message: 'Backend hatası: ${response.statusCode} - $errorBody',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } on FormatException catch (e) {
      throw ApiException(
        message: 'Geçersiz yanıt formatı: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException(
        message: 'Beklenmeyen hata: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Gmail email'lerini backend'den çek
  ///
  /// [accessToken] - Google OAuth access token
  /// [category] - Email kategorisi filtresi (null = tüm kategorilerden çek): 'inbox', 'sent', 'spam', 'drafts', 'promotions', 'social', 'updates', 'forums'
  /// [limit] - Kaç email getirilecek (max 100, kategori null ise tüm kategorilerden)
  Future<BackendEmailResponse> fetchGmailEmails({
    required String accessToken,
    String? category,
    int limit = 50,
  }) async {
    try {
      // URL oluştur
      final url = Uri.parse('$baseUrl/api/emails/gmail').replace(
        queryParameters: {
          if (category != null) 'category': category,
          'limit': limit.toString(),
        },
      );

      debugPrint('📧 Backend\'e Gmail email isteği gönderiliyor...');
      debugPrint('   URL: $url');
      debugPrint('   Category: ${category ?? "all"}');
      debugPrint('   Limit: $limit');

      // Authorization header ile istek gönder
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw NetworkException(
            message: 'Backend isteği zaman aşımına uğradı',
          );
        },
      );

      debugPrint('📧 Backend yanıtı: Status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmailResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
          message: 'Access token geçersiz veya süresi dolmuş. Lütfen tekrar giriş yapın.',
        );
      } else if (response.statusCode == 403) {
        throw ApiException(
          message: 'Gmail okuma yetkisi yok. Lütfen izinleri kontrol edin.',
        );
      } else {
        final errorBody = response.body;
        debugPrint('❌ Backend hatası: $errorBody');
        throw ApiException(
          message: 'Backend hatası: ${response.statusCode} - $errorBody',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } on FormatException catch (e) {
      throw ApiException(
        message: 'Geçersiz yanıt formatı: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'Beklenmeyen hata: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Redis'ten tüm görev çıkarımlarını çek
  ///
  /// [provider] - Provider filtresi: 'gmail', 'outlook' veya null (tümü)
  /// Belirli bir email için Redis'teki n8n task verisini getir
  Future<Map<String, dynamic>?> getTaskExtraction({
    required String emailId,
    required String provider,
  }) async {
    try {
      // Email ID'yi URL encode et (özel karakterler için)
      final encodedEmailId = Uri.encodeComponent(emailId);
      final url = Uri.parse('$baseUrl/api/redis/tasks/$provider/$encodedEmailId');

      debugPrint('📦 Redis\'ten n8n task verisi çekiliyor...');
      debugPrint('   URL: $url');
      debugPrint('   Email ID: $emailId');
      debugPrint('   Provider: $provider');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw NetworkException(
            message: 'Redis isteği zaman aşımına uğradı',
          );
        },
      );

      debugPrint('📦 Redis yanıtı: Status=${response.statusCode}');
      debugPrint(
          '📦 Redis yanıt body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('📦 Redis data keys: ${data.keys.toList()}');
        debugPrint('📦 Redis found: ${data['found']}');

        if (data['found'] == true && data['data'] != null) {
          final taskData = data['data'] as Map<String, dynamic>;
          debugPrint('📦 Redis taskData keys: ${taskData.keys.toList()}');

          // Backend'den gelen format: {email: {...}, task_data: {...}}
          // task_data'yı döndür
          if (taskData.containsKey('task_data')) {
            final extractedTaskData = taskData['task_data'] as Map<String, dynamic>?;
            debugPrint('✅ task_data bulundu, keys: ${extractedTaskData?.keys.toList() ?? []}');
            if (extractedTaskData != null && extractedTaskData.containsKey('summary')) {
              debugPrint('📦 task_data summary: ${extractedTaskData['summary']}');
            }
            return extractedTaskData;
          }
          // Eğer direkt task_data yoksa, tüm data'yı döndür (eski format)
          debugPrint('⚠️ task_data key\'i bulunamadı, tüm data döndürülüyor');
          return taskData;
        }
        debugPrint('⚠️ Redis\'te veri bulunamadı (found=false veya data=null)');
        return null;
      } else {
        debugPrint('❌ Redis hatası: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is NetworkException) rethrow;
      debugPrint('❌ Redis task verisi çekme hatası: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTasksFromRedis({
    String? provider,
  }) async {
    try {
      // URL oluştur
      final url = Uri.parse('$baseUrl/api/redis/tasks').replace(
        queryParameters: {
          if (provider != null) 'provider': provider,
        },
      );

      debugPrint('📦 Redis\'ten görevler çekiliyor...');
      debugPrint('   URL: $url');
      debugPrint('   Provider: ${provider ?? "all"}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw NetworkException(
            message: 'Redis isteği zaman aşımına uğradı',
          );
        },
      );

      debugPrint('📦 Redis yanıtı: Status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Backend response formatı: {"connected": true, "total": X, "tasks": [...]}
        if (data['connected'] == false) {
          debugPrint('⚠️ Redis bağlantısı yok');
          return [];
        }

        final tasks = (data['tasks'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

        debugPrint('✅ Redis\'ten ${tasks.length} görev alındı');
        return tasks;
      } else {
        final errorBody = response.body;
        debugPrint('❌ Redis hatası: $errorBody');
        throw ApiException(
          message: 'Redis hatası: ${response.statusCode} - $errorBody',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'Beklenmeyen hata: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Redis durumunu kontrol et
  Future<Map<String, dynamic>> getRedisStatus() async {
    try {
      final url = Uri.parse('$baseUrl/api/redis/status');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return {'connected': false, 'error': 'Status check failed: ${response.statusCode}'};
    } catch (e) {
      return {'connected': false, 'error': e.toString()};
    }
  }

  /// Redis'ten tarih aralığına göre email ve task verilerini çek
  ///
  /// [startDate] - Başlangıç tarihi (ISO 8601 format)
  /// [endDate] - Bitiş tarihi (ISO 8601 format)
  /// [provider] - Provider filtresi: 'gmail', 'outlook' veya null (tümü)
  ///
  /// Bu metod, sesli asistan "5 gün önceki maillerimi özetle" gibi komutlar için kullanılır
  Future<List<Map<String, dynamic>>> getEmailsByDateRange({
    required String startDate,
    required String endDate,
    String? provider,
  }) async {
    try {
      // URL oluştur
      final url = Uri.parse('$baseUrl/api/redis/emails').replace(
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          if (provider != null) 'provider': provider,
        },
      );

      debugPrint('📧 Redis\'ten tarih bazlı email isteği gönderiliyor...');
      debugPrint('   URL: $url');
      debugPrint('   Tarih aralığı: $startDate - $endDate');
      debugPrint('   Provider: ${provider ?? "all"}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw NetworkException(
            message: 'Redis isteği zaman aşımına uğradı',
          );
        },
      );

      debugPrint('📧 Redis yanıtı: Status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Backend response formatı: {"connected": true, "total": X, "emails": [...]}
        if (data['connected'] == false) {
          debugPrint('⚠️ Redis bağlantısı yok');
          return [];
        }

        final emails = (data['emails'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

        debugPrint('✅ Redis\'ten ${emails.length} email alındı (tarih aralığı)');
        return emails;
      } else {
        final errorBody = response.body;
        debugPrint('❌ Redis hatası: $errorBody');
        throw ApiException(
          message: 'Redis hatası: ${response.statusCode} - $errorBody',
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Ağ hatası: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('❌ Redis tarih bazlı email çekme hatası: $e');
      return [];
    }
  }

  // ==================== GMAIL EMAIL OPERATIONS ====================

  /// Gmail email gönder
  Future<BackendEmail> sendGmailEmail({
    required String accessToken,
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/send');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'to_emails': toEmails,
              'subject': subject,
              if (plainText != null) 'plain_text': plainText,
              if (htmlContent != null) 'html_content': htmlContent,
              if (ccEmails != null && ccEmails.isNotEmpty) 'cc_emails': ccEmails,
              if (bccEmails != null && bccEmails.isNotEmpty) 'bcc_emails': bccEmails,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email gönderme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email gönderme hatası: ${e.toString()}');
    }
  }

  /// Gmail email'i okundu olarak işaretle
  Future<BackendEmail> markGmailAsRead({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/$messageId/mark-read');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email okundu işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email okundu işaretleme hatası: ${e.toString()}');
    }
  }

  /// Gmail email'i okunmamış olarak işaretle
  Future<BackendEmail> markGmailAsUnread({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/$messageId/mark-unread');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email okunmamış işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email okunmamış işaretleme hatası: ${e.toString()}');
    }
  }

  /// Gmail email'i önemli olarak işaretle/kaldır
  Future<BackendEmail> toggleGmailImportant({
    required String accessToken,
    required String messageId,
    required bool isImportant,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/$messageId/toggle-important');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'is_important': isImportant}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email önemli işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email önemli işaretleme hatası: ${e.toString()}');
    }
  }

  /// Gmail email'i sil
  Future<void> deleteGmailEmail({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/$messageId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Email silme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email silme hatası: ${e.toString()}');
    }
  }

  /// Gmail email taslağı kaydet/güncelle
  Future<BackendEmail> saveGmailDraft({
    required String accessToken,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? draftId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/gmail/drafts');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'subject': subject,
              if (plainText != null) 'plain_text': plainText,
              if (htmlContent != null) 'html_content': htmlContent,
              if (toEmails != null && toEmails.isNotEmpty) 'to_emails': toEmails,
              if (ccEmails != null && ccEmails.isNotEmpty) 'cc_emails': ccEmails,
              if (bccEmails != null && bccEmails.isNotEmpty) 'bcc_emails': bccEmails,
              if (draftId != null) 'draft_id': draftId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email taslağı kaydetme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email taslağı kaydetme hatası: ${e.toString()}');
    }
  }

  // ==================== OUTLOOK EMAIL OPERATIONS ====================

  /// Outlook email gönder
  Future<BackendEmail> sendOutlookEmail({
    required String accessToken,
    required List<String> toEmails,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? ccEmails,
    List<String>? bccEmails,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/send');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'to_emails': toEmails,
              'subject': subject,
              if (plainText != null) 'plain_text': plainText,
              if (htmlContent != null) 'html_content': htmlContent,
              if (ccEmails != null && ccEmails.isNotEmpty) 'cc_emails': ccEmails,
              if (bccEmails != null && bccEmails.isNotEmpty) 'bcc_emails': bccEmails,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email gönderme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email gönderme hatası: ${e.toString()}');
    }
  }

  /// Outlook email'i okundu olarak işaretle
  Future<BackendEmail> markOutlookAsRead({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/$messageId/mark-read');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email okundu işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email okundu işaretleme hatası: ${e.toString()}');
    }
  }

  /// Outlook email'i okunmamış olarak işaretle
  Future<BackendEmail> markOutlookAsUnread({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/$messageId/mark-unread');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email okunmamış işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email okunmamış işaretleme hatası: ${e.toString()}');
    }
  }

  /// Outlook email'i önemli olarak işaretle/kaldır
  Future<BackendEmail> toggleOutlookImportant({
    required String accessToken,
    required String messageId,
    required bool isImportant,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/$messageId/toggle-important');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'is_important': isImportant}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email önemli işaretleme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email önemli işaretleme hatası: ${e.toString()}');
    }
  }

  /// Outlook email'i sil
  Future<void> deleteOutlookEmail({
    required String accessToken,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/$messageId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Email silme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email silme hatası: ${e.toString()}');
    }
  }

  /// Yeni email var mı kontrol et (polling için optimize edilmiş)
  ///
  /// [provider] - Provider filtresi: 'gmail' veya 'outlook' (null = tümü)
  /// [lastCheck] - Son kontrol zamanı (ISO format)
  ///
  /// Returns:
  /// {
  ///   "has_new_emails": true,
  ///   "gmail_count": 5,
  ///   "outlook_count": 3,
  ///   "total_count": 8,
  ///   "new_count": 2,
  ///   "last_email_timestamp": "2024-01-01T12:00:00Z"
  /// }
  Future<Map<String, dynamic>> checkNewEmails({
    String? provider,
    DateTime? lastCheck,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/check-new-emails').replace(
        queryParameters: {
          if (provider != null) 'provider': provider,
          if (lastCheck != null) 'last_check': lastCheck.toIso8601String(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Email check: ${data['new_count']} yeni email');
        return data;
      } else {
        throw ApiException(
          message: 'Email kontrol hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email kontrol hatası: ${e.toString()}');
    }
  }

  /// Email account'u backend'e bağla (entegre et)
  /// Bu sayede background scheduler otomatik olarak email'leri çekecek
  Future<Map<String, dynamic>> connectEmailAccount({
    required String provider, // "gmail" veya "outlook"
    required String email,
    required String accessToken,
    String? refreshToken,
    int? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/accounts/connect');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'provider': provider,
              'email': email,
              'access_token': accessToken,
              if (refreshToken != null) 'refresh_token': refreshToken,
              if (userId != null) 'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Email account backend\'e bağlandı: $email ($provider)');
        debugPrint('   Account ID: ${data['account_id']}');
        debugPrint('   Background scheduler otomatik olarak email\'leri çekecek');
        return data;
      } else {
        throw ApiException(
          message: 'Email account bağlama hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email account bağlama hatası: ${e.toString()}');
    }
  }

  /// Outlook email taslağı kaydet/güncelle
  Future<BackendEmail> saveOutlookDraft({
    required String accessToken,
    required String subject,
    String? plainText,
    String? htmlContent,
    List<String>? toEmails,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? draftId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/emails/outlook/drafts');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'subject': subject,
              if (plainText != null) 'plain_text': plainText,
              if (htmlContent != null) 'html_content': htmlContent,
              if (toEmails != null && toEmails.isNotEmpty) 'to_emails': toEmails,
              if (ccEmails != null && ccEmails.isNotEmpty) 'cc_emails': ccEmails,
              if (bccEmails != null && bccEmails.isNotEmpty) 'bcc_emails': bccEmails,
              if (draftId != null) 'draft_id': draftId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BackendEmail.fromJson(data);
      } else {
        throw ApiException(
          message: 'Email taslağı kaydetme hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Email taslağı kaydetme hatası: ${e.toString()}');
    }
  }
}

/// Backend email response modeli
class BackendEmailResponse {
  final List<BackendEmail> emails;
  final int total;
  final String category;

  BackendEmailResponse({
    required this.emails,
    required this.total,
    required this.category,
  });

  factory BackendEmailResponse.fromJson(Map<String, dynamic> json) {
    return BackendEmailResponse(
      emails: (json['emails'] as List<dynamic>).map((e) => BackendEmail.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
      category: json['category'] as String,
    );
  }
}

/// Backend email modeli
class BackendEmail {
  final String id;
  final String subject;
  final String sender;
  final String? recipient;
  final String? preview;
  final String? plainText;
  final String? htmlContent;
  final DateTime receivedDate;
  final bool isRead;
  final String category;
  final bool hasAttachments;

  BackendEmail({
    required this.id,
    required this.subject,
    required this.sender,
    this.recipient,
    this.preview,
    this.plainText,
    this.htmlContent,
    required this.receivedDate,
    required this.isRead,
    required this.category,
    required this.hasAttachments,
  });

  factory BackendEmail.fromJson(Map<String, dynamic> json) {
    return BackendEmail(
      id: json['id'] as String,
      subject: json['subject'] as String,
      sender: json['sender'] as String,
      recipient: json['recipient'] as String?,
      preview: json['preview'] as String?,
      plainText: json['plain_text'] as String?,
      htmlContent: json['html_content'] as String?,
      receivedDate: DateTime.parse(json['received_date'] as String),
      isRead: json['is_read'] as bool,
      category: json['category'] as String,
      hasAttachments: json['has_attachments'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'sender': sender,
      'recipient': recipient,
      'preview': preview,
      'received_date': receivedDate.toIso8601String(),
      'is_read': isRead,
      'category': category,
      'has_attachments': hasAttachments,
    };
  }
}
