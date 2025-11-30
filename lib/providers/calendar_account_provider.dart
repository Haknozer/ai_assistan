import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/models/calendar_account.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ai_asisstan/core/database/database_service.dart';

/// Calendar account repository
class CalendarAccountRepository {
  final DatabaseService _databaseService;

  CalendarAccountRepository({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  /// Tüm calendar hesaplarını getir
  Future<List<CalendarAccount>> getCalendarAccounts({int? userId}) async {
    final db = await _databaseService.database;

    final maps = userId != null
        ? await db.query(
            'calendar_accounts',
            where: 'user_id = ? AND is_active = 1',
            whereArgs: [userId],
          )
        : await db.query('calendar_accounts', where: 'is_active = 1');

    return maps.map((map) => CalendarAccount.fromDatabase(map)).toList();
  }

  /// Calendar hesabı bağla
  Future<CalendarAccount> connectCalendarAccount({
    required int userId,
    required String emailAddress,
    required CalendarProvider provider,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpires,
    String? displayName,
  }) async {
    final now = DateTime.now();
    final account = CalendarAccount(
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

    final db = await _databaseService.database;
    await _saveAccountToCache(db, account);

    return account;
  }

  /// Calendar hesabı bağlantısını kes
  Future<void> disconnectCalendarAccount(int accountId) async {
    final db = await _databaseService.database;
    await db.delete('calendar_accounts', where: 'id = ?', whereArgs: [accountId]);
    debugPrint('Calendar account $accountId local database\'den silindi');
  }

  Future<void> _saveAccountToCache(Database db, CalendarAccount account) async {
    await db.transaction((txn) async {
      await _saveAccountToCacheInTransaction(txn, account);
    });
  }

  Future<void> _saveAccountToCacheInTransaction(dynamic txn, CalendarAccount account) async {
    final data = account.toDatabase();

    final existing = await txn.query(
      'calendar_accounts',
      where: 'id = ? OR email_address = ?',
      whereArgs: [account.id ?? -1, account.emailAddress],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await txn.update('calendar_accounts', data, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await txn.insert('calendar_accounts', data);
    }
  }
}

/// Calendar account repository provider
final calendarAccountRepositoryProvider = Provider<CalendarAccountRepository>((ref) {
  return CalendarAccountRepository();
});

/// Calendar accounts listesi provider
final calendarAccountsProvider =
    FutureProvider.family<List<CalendarAccount>, CalendarAccountsParams>((ref, params) async {
  final repository = ref.watch(calendarAccountRepositoryProvider);
  return repository.getCalendarAccounts(userId: params.userId);
});

/// Calendar accounts parametreleri
class CalendarAccountsParams {
  final int? userId;

  CalendarAccountsParams({
    this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarAccountsParams && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
