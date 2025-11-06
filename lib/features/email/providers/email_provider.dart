import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/email_repository.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';

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

  EmailNotifier(this._repository, this._params) : super(const AsyncValue.loading()) {
    _loadEmails();
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
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
  }
}

/// Email notifier provider
final emailNotifierProvider =
    StateNotifierProvider.family<EmailNotifier, AsyncValue<List<Email>>, EmailListParams>((ref, params) {
  final repository = ref.watch(emailRepositoryProvider);
  return EmailNotifier(repository, params);
});
