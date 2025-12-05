import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/repositories/email_repository.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/services/n8n_forwarder_service.dart';
import 'package:ai_asisstan/services/n8n_response_storage_service.dart';
import 'package:ai_asisstan/core/utils/logger.dart';

/// Email repository provider
final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  return EmailRepository();
});

/// Email listesi provider
final emailsProvider = FutureProvider.family<List<Email>, EmailListParams>((ref, params) async {
  final repository = ref.watch(emailRepositoryProvider);
  return repository.getEmails(
    accountId: params.accountId,
    folder: params.folder,
    limit: params.limit,
    offset: params.offset,
    accessToken: params.accessToken,
  );
});

/// Email detay provider
final emailByIdProvider = FutureProvider.family<Email?, int>((ref, emailId) async {
  final repository = ref.watch(emailRepositoryProvider);
  return repository.getEmailById(emailId);
});

/// Email listesi parametreleri
class EmailListParams {
  final int? accountId;
  final String? folder;
  final int? limit;
  final int? offset;
  final String? accessToken;

  EmailListParams({
    this.accountId,
    this.folder,
    this.limit,
    this.offset,
    this.accessToken,
  });

  EmailListParams copyWith({
    int? accountId,
    String? folder,
    int? limit,
    int? offset,
    String? accessToken,
  }) {
    return EmailListParams(
      accountId: accountId ?? this.accountId,
      folder: folder ?? this.folder,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailListParams &&
        other.accountId == accountId &&
        other.folder == folder &&
        other.limit == limit &&
        other.offset == offset &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode {
    return Object.hash(accountId, folder, limit, offset, accessToken);
  }
}

/// Email işlemleri için provider (stateful)
class EmailNotifier extends StateNotifier<AsyncValue<List<Email>>> {
  final EmailRepository _repository;
  final EmailListParams _params;
  final Set<String> _forwardedEmailIds = {}; // Forward edilen email'leri takip et
  final N8nForwarderService _n8nForwarder = N8nForwarderService();
  static const String _forwardedEmailsKey = 'n8n_forwarded_email_ids';

  EmailNotifier(this._repository, this._params) : super(const AsyncValue.loading()) {
    _loadForwardedEmailIds();
    _loadEmails();
  }

  /// Account ID'yi döndürür
  int? get accountId => _params.accountId;

  /// SharedPreferences'tan forward edilen email ID'lerini yükle
  Future<void> _loadForwardedEmailIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_forwardedEmailsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _forwardedEmailIds.addAll(decoded.map((e) => e.toString()));
        AppLogger.debug('Forward edilen ${_forwardedEmailIds.length} email ID yüklendi', 'N8N');
      }
    } catch (e) {
      AppLogger.error('Forward edilen email ID\'leri yüklenirken hata', tag: 'N8N', error: e);
    }
  }

  /// Forward edilen email ID'lerini SharedPreferences'a kaydet
  Future<void> _saveForwardedEmailIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_forwardedEmailIds.toList());
      await prefs.setString(_forwardedEmailsKey, jsonString);
    } catch (e) {
      AppLogger.error('Forward edilen email ID\'leri kaydedilirken hata', tag: 'N8N', error: e);
    }
  }

  /// Forward edilen email ID'lerini temizle (tüm email'ler tekrar forward edilebilir)
  Future<void> clearForwardedEmailIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_forwardedEmailsKey);
      _forwardedEmailIds.clear();
      AppLogger.info('Forward edilen email ID\'leri temizlendi', 'N8N');
    } catch (e) {
      AppLogger.error('Forward edilen email ID\'leri temizlenirken hata', tag: 'N8N', error: e);
    }
  }

  Future<void> _loadEmails() async {
    state = const AsyncValue.loading();
    try {
      final emails = await _repository.getEmails(
        accountId: _params.accountId,
        folder: _params.folder,
        limit: _params.limit,
        offset: _params.offset,
        accessToken: _params.accessToken,
      );
      state = AsyncValue.data(emails);
      
      // Yeni email'leri n8n'e forward et
      _forwardNewEmails(emails).catchError((e) {
        AppLogger.error('Error forwarding emails to n8n', tag: 'N8N', error: e);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Yeni email'leri n8n'e forward et (daha önce forward edilmemiş olanlar)
  Future<void> _forwardNewEmails(List<Email> emails) async {
    for (final email in emails) {
      // Daha önce forward edilmişse atla
      final emailId = email.messageId ?? email.id?.toString() ?? '';
      if (emailId.isEmpty || _forwardedEmailIds.contains(emailId)) {
        continue;
      }

      // Sadece inbox'taki okunmamış email'leri forward et (isteğe bağlı - tüm email'leri forward etmek için bu kontrolü kaldırabilirsiniz)
      // if (email.folder != EmailFolder.inbox || email.isRead) {
      //   continue;
      // }

      // Forward et ve n8n'den dönen cevabı logla
      final n8nResponse = await _n8nForwarder.forwardEmailMessageAndWait(
        userId: email.userId.toString(),
        accountId: email.accountId,
        messageId: emailId,
        fromEmail: email.fromEmail,
        fromName: email.fromName,
        subject: email.subject,
        plainText: email.plainText,
        htmlContent: email.htmlContent,
        toEmails: email.toEmails,
        ccEmails: email.ccEmails,
        bccEmails: email.bccEmails,
        receivedDate: email.receivedDate,
        isRead: email.isRead,
        folder: email.folder.name, // EmailFolder.inbox -> inbox
      );

      // n8n'den dönen cevabı console'a yazdır
      AppLogger.debug('n8n email response: $n8nResponse', 'N8N');

      // n8n response'u kalıcı olarak kaydet
      if (n8nResponse != null) {
        await N8nResponseStorageService().saveEmailResponse(emailId, n8nResponse);
      }

      // Forward edildi olarak işaretle ve kalıcı olarak kaydet
      _forwardedEmailIds.add(emailId);
      _saveForwardedEmailIds().catchError((e) {
        AppLogger.error('Forward edilen email ID kaydedilemedi', tag: 'N8N', error: e);
      });
    }
  }

  /// Email listesini yenile
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final emails = await _repository.getEmails(
        accountId: _params.accountId,
        folder: _params.folder,
        limit: _params.limit,
        offset: _params.offset,
        accessToken: _params.accessToken,
      );
      state = AsyncValue.data(emails);
      
      // Yeni email'leri n8n'e forward et
      _forwardNewEmails(emails).catchError((e) {
        AppLogger.error('Error forwarding emails to n8n', tag: 'N8N', error: e);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Email'i okundu olarak işaretle
  Future<void> markAsRead(String messageId, {String? accessToken}) async {
    final currentEmails = state.value;
    if (currentEmails == null) return;

    // Optimistic update - messageId ile karşılaştır
    final updatedEmails = currentEmails.map((email) {
      if (email.messageId == messageId) {
        return email.copyWith(
          status: EmailStatus.read,
          isRead: true,
        );
      }
      return email;
    }).toList();

    state = AsyncValue.data(updatedEmails);

    try {
      // messageId'yi int'e çevir (Gmail API messageId string kullanır ama int olarak parse edilebilir)
      final emailId = int.tryParse(messageId) ?? 0;
      if (emailId == 0) {
        debugPrint('markAsRead: Invalid messageId: $messageId');
        return;
      }
      
      await _repository.markAsRead(emailId, accessToken: accessToken);
      
      // Başarılı olursa liste yeniden yüklenir
      await refresh();
    } on NotFoundException {
      // 404 hatası - email bulunamadı, ama optimistic update zaten yapıldı
      // Sadece refresh yap, hata gösterme
      debugPrint('markAsRead: Email not found (messageId: $messageId), refreshing list');
      await refresh();
    } catch (e) {
      // Hata varsa geri al ve hata göster
      debugPrint('markAsRead hatası: ${e.toString()}');
      state = AsyncValue.data(currentEmails);
      // Hata durumunda da refresh yap, belki email başka bir yerde güncellenmiştir
      await refresh();
    }
  }

  /// Email'i okunmamış olarak işaretle
  Future<void> markAsUnread(int emailId, {String? accessToken}) async {
    final currentEmails = state.value;
    if (currentEmails == null) return;

    // Optimistic update
    final updatedEmails = currentEmails.map((email) {
      if (email.id == emailId) {
        return email.copyWith(
          status: EmailStatus.unread,
          isRead: false,
        );
      }
      return email;
    }).toList();

    state = AsyncValue.data(updatedEmails);

    try {
      await _repository.markAsUnread(emailId, accessToken: accessToken);
      await refresh();
    } catch (e, stack) {
      state = AsyncValue.data(currentEmails);
      state = AsyncValue.error(e, stack);
    }
  }

  /// Email'i önemli olarak işaretle/kaldır
  Future<void> toggleImportant(int emailId, bool isImportant, {String? accessToken}) async {
    final currentEmails = state.value;
    if (currentEmails == null) return;

    // Optimistic update
    final updatedEmails = currentEmails.map((email) {
      if (email.id == emailId) {
        return email.copyWith(
          importance: isImportant ? EmailImportance.important : EmailImportance.normal,
        );
      }
      return email;
    }).toList();

    state = AsyncValue.data(updatedEmails);

    try {
      await _repository.toggleImportant(emailId, isImportant, accessToken: accessToken);
      await refresh();
    } catch (e, stack) {
      state = AsyncValue.data(currentEmails);
      state = AsyncValue.error(e, stack);
    }
  }

  /// Email sil
  Future<void> deleteEmail(int emailId, {String? accessToken}) async {
    final currentEmails = state.value;
    if (currentEmails == null) return;

    // Optimistic update
    final updatedEmails = currentEmails.where((email) => email.id != emailId).toList();
    state = AsyncValue.data(updatedEmails);

    try {
      await _repository.deleteEmail(emailId, accessToken: accessToken);
    } catch (e, stack) {
      // Hata varsa geri al
      state = AsyncValue.data(currentEmails);
      state = AsyncValue.error(e, stack);
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
    try {
      final email = await _repository.sendEmail(
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

      // Listeyi güncelle
      final currentEmails = state.value ?? [];
      state = AsyncValue.data([email, ...currentEmails]);

      return email;
    } catch (e) {
      // Hata durumunda logla
      AppLogger.error('Email gönderme hatası', tag: 'EMAIL', error: e);
      rethrow;
    }
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
    try {
      final email = await _repository.saveDraft(
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

      // Listeyi güncelle
      final currentEmails = state.value ?? [];
      state = AsyncValue.data([email, ...currentEmails]);

      return email;
    } catch (e) {
      // Hata durumunda logla
      AppLogger.error('Taslak kaydetme hatası', tag: 'EMAIL', error: e);
      rethrow;
    }
  }
}

/// Email notifier provider
final emailNotifierProvider =
    StateNotifierProvider.family<EmailNotifier, AsyncValue<List<Email>>, EmailListParams>((ref, params) {
  final repository = ref.watch(emailRepositoryProvider);
  return EmailNotifier(repository, params);
});
