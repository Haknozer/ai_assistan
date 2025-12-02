import '../models/user_setting.dart';
import '../core/database/database_service.dart';

class UserSettingRepository {
  static const String _tableName = 'user_settings';

  // Kullanıcı ayarlarını getir
  Future<List<UserSetting>> getUserSettings(int userId) async {
    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'category ASC, setting_key ASC',
      );

      return maps.map((map) => UserSetting.fromDatabase(map)).toList();
    } catch (e) {
      throw Exception('Kullanıcı ayarları alınamadı: $e');
    }
  }

  // Belirli bir ayarı getir
  Future<UserSetting?> getSetting(int userId, String settingKey) async {
    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND setting_key = ?',
        whereArgs: [userId, settingKey],
      );

      if (maps.isNotEmpty) {
        return UserSetting.fromDatabase(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Ayar alınamadı: $e');
    }
  }

  // Kategoriye göre ayarları getir
  Future<List<UserSetting>> getSettingsByCategory(int userId, SettingCategory category) async {
    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND category = ?',
        whereArgs: [userId, category.name],
        orderBy: 'setting_key ASC',
      );

      return maps.map((map) => UserSetting.fromDatabase(map)).toList();
    } catch (e) {
      throw Exception('Kategori ayarları alınamadı: $e');
    }
  }

  // Ayar oluştur veya güncelle
  Future<UserSetting> upsertSetting(UserSetting setting) async {
    try {
      final db = await DatabaseService.instance.database;

      // Önce ayarın var olup olmadığını kontrol et
      final existing = await getSetting(setting.userId, setting.settingKey);

      if (existing != null) {
        // Güncelle
        await db.update(
          _tableName,
          setting.toDatabase(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return setting.copyWith(id: existing.id);
      } else {
        // Yeni kayıt
        final id = await db.insert(_tableName, setting.toDatabase());
        return setting.copyWith(id: id);
      }
    } catch (e) {
      throw Exception('Ayar kaydedilemedi: $e');
    }
  }

  // Birden fazla ayarı toplu olarak güncelle
  Future<void> upsertMultipleSettings(List<UserSetting> settings) async {
    try {
      final db = await DatabaseService.instance.database;
      final batch = db.batch();

      for (final setting in settings) {
        final existing = await getSetting(setting.userId, setting.settingKey);

        if (existing != null) {
          batch.update(
            _tableName,
            setting.toDatabase(),
            where: 'id = ?',
            whereArgs: [existing.id],
          );
        } else {
          batch.insert(_tableName, setting.toDatabase());
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ayarlar kaydedilemedi: $e');
    }
  }

  // Ayarı sil
  Future<void> deleteSetting(int userId, String settingKey) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(
        _tableName,
        where: 'user_id = ? AND setting_key = ?',
        whereArgs: [userId, settingKey],
      );
    } catch (e) {
      throw Exception('Ayar silinemedi: $e');
    }
  }

  // Kullanıcının tüm ayarlarını sil
  Future<void> deleteAllUserSettings(int userId) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Kullanıcı ayarları silinemedi: $e');
    }
  }

  // Varsayılan ayarları oluştur
  Future<List<UserSetting>> createDefaultSettings(int userId) async {
    final defaultSettings = [
      // Genel Ayarlar
      UserSetting.themeSetting(userId: userId, theme: 'system'),
      UserSetting.languageSetting(userId: userId, language: 'tr'),
      UserSetting(
        userId: userId,
        settingKey: 'auto_backup',
        settingValue: 'true',
        category: SettingCategory.general,
        updatedAt: DateTime.now(),
      ),

      // Bildirim Ayarları
      UserSetting.emailNotificationSetting(userId: userId, enabled: true),
      UserSetting(
        userId: userId,
        settingKey: 'push_notifications',
        settingValue: 'false',
        category: SettingCategory.notifications,
        updatedAt: DateTime.now(),
      ),
      UserSetting(
        userId: userId,
        settingKey: 'notification_sound',
        settingValue: 'true',
        category: SettingCategory.notifications,
        updatedAt: DateTime.now(),
      ),

      // E-posta Ayarları
      UserSetting.autoSyncSetting(userId: userId, enabled: false),
      UserSetting(
        userId: userId,
        settingKey: 'email_sync_interval',
        settingValue: '30',
        category: SettingCategory.email,
        updatedAt: DateTime.now(),
      ),

      // Takvim Ayarları
      UserSetting(
        userId: userId,
        settingKey: 'calendar_reminder',
        settingValue: '15',
        category: SettingCategory.calendar,
        updatedAt: DateTime.now(),
      ),
      UserSetting(
        userId: userId,
        settingKey: 'calendar_sync',
        settingValue: 'true',
        category: SettingCategory.calendar,
        updatedAt: DateTime.now(),
      ),

      // Yapay Zeka Ayarları
      UserSetting.aiSummarySetting(userId: userId, enabled: true),
      UserSetting(
        userId: userId,
        settingKey: 'ai_suggestions',
        settingValue: 'true',
        category: SettingCategory.ai,
        updatedAt: DateTime.now(),
      ),

      // Gizlilik Ayarları
      UserSetting(
        userId: userId,
        settingKey: 'analytics_enabled',
        settingValue: 'true',
        category: SettingCategory.privacy,
        updatedAt: DateTime.now(),
      ),
      UserSetting(
        userId: userId,
        settingKey: 'crash_reporting',
        settingValue: 'true',
        category: SettingCategory.privacy,
        updatedAt: DateTime.now(),
      ),
      // Uygulama genel bulut senkronizasyon anahtarı
      UserSetting(
        userId: userId,
        settingKey: 'privacy_cloud_sync',
        // Varsayılan: kapalı, kullanıcı isterse açar
        settingValue: 'false',
        category: SettingCategory.privacy,
        updatedAt: DateTime.now(),
      ),
    ];

    try {
      await upsertMultipleSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      throw Exception('Varsayılan ayarlar oluşturulamadı: $e');
    }
  }

  // Ayar değerini string olarak al
  Future<String?> getSettingValue(int userId, String settingKey) async {
    try {
      final setting = await getSetting(userId, settingKey);
      return setting?.settingValue;
    } catch (e) {
      return null;
    }
  }

  // Ayar değerini boolean olarak al
  Future<bool> getBoolSettingValue(int userId, String settingKey, {bool defaultValue = false}) async {
    try {
      final value = await getSettingValue(userId, settingKey);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      return defaultValue;
    }
  }

  // Ayar değerini integer olarak al
  Future<int> getIntSettingValue(int userId, String settingKey, {int defaultValue = 0}) async {
    try {
      final value = await getSettingValue(userId, settingKey);
      return int.tryParse(value ?? '') ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // Basit ayar güncelleme metodu
  Future<void> updateSettingValue(int userId, String settingKey, String value, {SettingCategory? category}) async {
    try {
      final setting = UserSetting(
        userId: userId,
        settingKey: settingKey,
        settingValue: value,
        category: category ?? SettingCategory.general,
        updatedAt: DateTime.now(),
      );
      await upsertSetting(setting);
    } catch (e) {
      throw Exception('Ayar güncellenemedi: $e');
    }
  }
}
