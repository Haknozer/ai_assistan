import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_endpoints.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ai_asisstan/core/database/database_service.dart';

/// Email account repository
class EmailAccountRepository {
  final ApiClient _apiClient;
  final DatabaseService _databaseService;

  EmailAccountRepository({
    ApiClient? apiClient,
    DatabaseService? databaseService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _databaseService = databaseService ?? DatabaseService.instance;

  /// Tüm email hesaplarını getir
  Future<List<EmailAccount>> getEmailAccounts({int? userId, String? accessToken}) async {
    final db = await _databaseService.database;

    // Önce cache'den kontrol et
    try {
      final cachedAccounts = await _getCachedAccounts(db, userId: userId);
      if (cachedAccounts.isNotEmpty) {
        return cachedAccounts;
      }
    } catch (e) {
      // Cache hatası varsa API'den çek
    }

    // API'den çek
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _apiClient.get(
        ApiEndpoints.emailAccounts,
        queryParameters: queryParams,
        accessToken: accessToken,
      );

      final accountsData = response['data'] as List<dynamic>? ?? response['accounts'] as List<dynamic>? ?? [];
      final accounts = accountsData.map((json) => EmailAccount.fromJson(json as Map<String, dynamic>)).toList();

      // Cache'e kaydet
      await _saveAccountsToCache(db, accounts);

      return accounts;
    } catch (e) {
      // API hatası varsa cache'den döndür
      return await _getCachedAccounts(db, userId: userId);
    }
  }

  /// Email hesabı bağla
  /// API çağrısı başarısız olsa bile local database'e kaydeder
  Future<EmailAccount> connectEmailAccount({
    required int userId,
    required String emailAddress,
    required EmailProvider provider,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpires,
    String? displayName,
  }) async {
    EmailAccount account;

    // Önce API'ye kaydetmeyi dene
    try {
      final body = {
        'user_id': userId,
        'email_address': emailAddress,
        'provider': provider.name,
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (tokenExpires != null) 'token_expires': tokenExpires.toIso8601String(),
        if (displayName != null) 'display_name': displayName,
      };

      final response = await _apiClient.post(
        ApiEndpoints.connectEmailAccount,
        body: body,
      );

      final accountData = response['data'] ?? response;
      account = EmailAccount.fromJson(accountData as Map<String, dynamic>);
    } on ApiException catch (e) {
      // API hatası varsa (örn: api.example.com erişilemiyor), local database'e kaydet
      // Bu durumda yeni bir EmailAccount objesi oluştur
      final now = DateTime.now();
      account = EmailAccount(
        id: null, // Local database otomatik ID atayacak
        userId: userId,
        emailAddress: emailAddress,
        provider: provider,
        displayName: displayName,
        isActive: true,
        syncEnabled: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenExpires: tokenExpires,
        createdAt: now,
        updatedAt: now,
      );

      // API hatasını logla ama devam et
      debugPrint('API çağrısı başarısız, local database\'e kaydediliyor: ${e.message}');
    } catch (e) {
      // Beklenmeyen hata durumunda da local database'e kaydet
      final now = DateTime.now();
      account = EmailAccount(
        id: null,
        userId: userId,
        emailAddress: emailAddress,
        provider: provider,
        displayName: displayName,
        isActive: true,
        syncEnabled: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenExpires: tokenExpires,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('Email account kaydetme hatası (local database\'e kaydediliyor): ${e.toString()}');
    }

    // Her durumda local database'e kaydet
    final db = await _databaseService.database;
    await _saveAccountToCache(db, account);

    return account;
  }

  /// Email hesabı senkronize et
  Future<void> syncEmailAccount(int accountId, {String? accessToken}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.syncEmailAccount(accountId),
        accessToken: accessToken,
      );

      // Son senkronizasyon zamanını güncelle
      final db = await _databaseService.database;
      await db.update(
        'email_accounts',
        {'last_sync': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to sync email account: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Token yenile
  Future<EmailAccount> refreshToken(int accountId, {String? refreshToken}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken(accountId),
        body: refreshToken != null ? {'refresh_token': refreshToken} : null,
      );

      final accountData = response['data'] ?? response;
      final account = EmailAccount.fromJson(accountData as Map<String, dynamic>);

      // Cache'i güncelle
      final db = await _databaseService.database;
      await _saveAccountToCache(db, account);

      return account;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to refresh token: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Email hesabı bağlantısını kes
  /// API çağrısı başarısız olsa bile local database'den siler
  Future<void> disconnectEmailAccount(int accountId, {String? accessToken}) async {
    // Önce local database'den sil (backend yoksa bile çalışsın)
    final db = await _databaseService.database;

    try {
      // API'ye DELETE isteği gönder (backend varsa)
      try {
        await _apiClient.delete(
          ApiEndpoints.disconnectEmailAccount(accountId),
          accessToken: accessToken,
        );
      } on ApiException catch (e) {
        // API hatası olsa bile devam et (backend yoksa normal)
        // Sadece network hatalarını sessizce logla
        if (e.message.contains('Failed host lookup') ||
            e.message.contains('Network error') ||
            e.message.contains('api.example.com')) {
          debugPrint('API disconnect hatası (backend yok olabilir): ${e.message}');
        } else {
          // Diğer API hatalarını logla ama devam et
          debugPrint('API disconnect hatası: ${e.message}');
        }
      } catch (e) {
        // Beklenmeyen hatalar için de devam et
        debugPrint('API disconnect beklenmeyen hatası: ${e.toString()}');
      }

      // Cache'den sil (her durumda)
      await db.delete('email_accounts', where: 'id = ?', whereArgs: [accountId]);
      debugPrint('Email account $accountId local database\'den silindi');
    } catch (e) {
      // Database hatası durumunda hata fırlat
      throw ApiException(
        message: 'Failed to disconnect email account: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // Cache metodları

  Future<List<EmailAccount>> _getCachedAccounts(Database db, {int? userId}) async {
    final maps = userId != null
        ? await db.query(
            'email_accounts',
            where: 'user_id = ? AND is_active = 1',
            whereArgs: [userId],
          )
        : await db.query('email_accounts', where: 'is_active = 1');

    return maps.map((map) => EmailAccount.fromDatabase(map)).toList();
  }

  Future<void> _saveAccountsToCache(Database db, List<EmailAccount> accounts) async {
    await db.transaction((txn) async {
      for (final account in accounts) {
        await _saveAccountToCacheInTransaction(txn, account);
      }
    });
  }

  Future<void> _saveAccountToCache(Database db, EmailAccount account) async {
    await db.transaction((txn) async {
      await _saveAccountToCacheInTransaction(txn, account);
    });
  }

  Future<void> _saveAccountToCacheInTransaction(dynamic txn, EmailAccount account) async {
    final data = account.toDatabase();

    final existing = await txn.query(
      'email_accounts',
      where: 'id = ? OR email_address = ?',
      whereArgs: [account.id ?? -1, account.emailAddress],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await txn.update('email_accounts', data, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await txn.insert('email_accounts', data);
    }
  }
}

/// Email account repository provider
final emailAccountRepositoryProvider = Provider<EmailAccountRepository>((ref) {
  return EmailAccountRepository();
});

/// Email accounts listesi provider
final emailAccountsProvider = FutureProvider.family<List<EmailAccount>, EmailAccountsParams>((ref, params) async {
  final repository = ref.watch(emailAccountRepositoryProvider);
  return repository.getEmailAccounts(
    userId: params.userId,
    accessToken: params.accessToken,
  );
});

/// Email accounts parametreleri
class EmailAccountsParams {
  final int? userId;
  final String? accessToken;

  EmailAccountsParams({
    this.userId,
    this.accessToken,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailAccountsParams && other.userId == userId && other.accessToken == accessToken;
  }

  @override
  int get hashCode => Object.hash(userId, accessToken);
}

/// Email account notifier
class EmailAccountNotifier extends StateNotifier<AsyncValue<List<EmailAccount>>> {
  final EmailAccountRepository _repository;
  final EmailAccountsParams _params;

  EmailAccountNotifier(this._repository, this._params) : super(const AsyncValue.loading()) {
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await _repository.getEmailAccounts(
        userId: _params.userId,
        accessToken: _params.accessToken,
      );
      state = AsyncValue.data(accounts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Listeyi yenile
  Future<void> refresh() async {
    await _loadAccounts();
  }

  /// Email hesabı bağla
  Future<EmailAccount> connectAccount({
    required int userId,
    required String emailAddress,
    required EmailProvider provider,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpires,
    String? displayName,
  }) async {
    final account = await _repository.connectEmailAccount(
      userId: userId,
      emailAddress: emailAddress,
      provider: provider,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpires: tokenExpires,
      displayName: displayName,
    );

    // Listeyi güncelle
    final currentAccounts = state.value ?? [];
    state = AsyncValue.data([...currentAccounts, account]);

    return account;
  }

  /// Email hesabı senkronize et
  Future<void> syncAccount(int accountId, {String? accessToken}) async {
    await _repository.syncEmailAccount(accountId, accessToken: accessToken);
    await refresh();
  }

  /// Token yenile
  Future<EmailAccount> refreshTokenForAccount(int accountId, {String? refreshToken}) async {
    final account = await _repository.refreshToken(accountId, refreshToken: refreshToken);
    await refresh();
    return account;
  }

  /// Email hesabı bağlantısını kes
  Future<void> disconnectAccount(int accountId, {String? accessToken}) async {
    await _repository.disconnectEmailAccount(accountId, accessToken: accessToken);
    await refresh();
  }
}

/// Email account notifier provider
final emailAccountNotifierProvider =
    StateNotifierProvider.family<EmailAccountNotifier, AsyncValue<List<EmailAccount>>, EmailAccountsParams>(
        (ref, params) {
  final repository = ref.watch(emailAccountRepositoryProvider);
  return EmailAccountNotifier(repository, params);
});
