import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_setting.dart';
import '../repositories/user_setting_repository.dart';
import '../providers/user_provider.dart';

// part 'user_setting_provider.g.dart'; // Commented out due to generation issues

// Traditional Riverpod providers
final userSettingRepositoryProvider = Provider<UserSettingRepository>((ref) {
  return UserSettingRepository();
});

final userSettingNotifierProvider = StateNotifierProvider<UserSettingNotifier, AsyncValue<List<UserSetting>>>((ref) {
  return UserSettingNotifier();
});

class UserSettingNotifier extends StateNotifier<AsyncValue<List<UserSetting>>> {
  late UserSettingRepository _repository;

  UserSettingNotifier() : super(const AsyncValue.loading()) {
    _repository = UserSettingRepository();
  }

  // Kullanıcı ayarlarını yükle
  Future<void> loadUserSettings(int userId) async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getUserSettings(userId);

      // Eğer hiç ayar yoksa varsayılan ayarları oluştur
      if (settings.isEmpty) {
        await _repository.createDefaultSettings(userId);
        final defaultSettings = await _repository.getUserSettings(userId);
        state = AsyncValue.data(defaultSettings);
      } else {
        state = AsyncValue.data(settings);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Ayar güncelle
  Future<void> updateSetting(UserSetting setting) async {
    try {
      final updatedSetting = await _repository.upsertSetting(setting);

      // State'i güncelle
      final currentSettings = state.value ?? [];
      final updatedSettings = currentSettings
          .map((s) => s.settingKey == setting.settingKey && s.userId == setting.userId ? updatedSetting : s)
          .toList();

      state = AsyncValue.data(updatedSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Ayar değerini basitçe güncelle
  Future<void> updateSettingValue(int userId, String settingKey, String value, {SettingCategory? category}) async {
    try {
      final setting = UserSetting(
        userId: userId,
        settingKey: settingKey,
        settingValue: value,
        category: category ?? SettingCategory.general,
        updatedAt: DateTime.now(),
      );

      await updateSetting(setting);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Boolean ayar güncelle
  Future<void> updateBoolSetting(int userId, String settingKey, bool value, {SettingCategory? category}) async {
    await updateSettingValue(userId, settingKey, value.toString(), category: category);
  }

  // Ayarı sil
  Future<void> deleteSetting(int userId, String settingKey) async {
    try {
      await _repository.deleteSetting(userId, settingKey);

      // State'den de kaldır
      final currentSettings = state.value ?? [];
      final updatedSettings =
          currentSettings.where((s) => !(s.settingKey == settingKey && s.userId == userId)).toList();

      state = AsyncValue.data(updatedSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Kategoriye göre ayarları getir
  Future<List<UserSetting>> getSettingsByCategory(int userId, SettingCategory category) async {
    try {
      return await _repository.getSettingsByCategory(userId, category);
    } catch (e) {
      return [];
    }
  }

  // Belirli bir ayarı getir
  Future<UserSetting?> getSetting(int userId, String settingKey) async {
    try {
      return await _repository.getSetting(userId, settingKey);
    } catch (e) {
      return null;
    }
  }

  // Ayar değerini string olarak al
  Future<String?> getSettingValue(int userId, String settingKey) async {
    try {
      return await _repository.getSettingValue(userId, settingKey);
    } catch (e) {
      return null;
    }
  }

  // Ayar değerini boolean olarak al
  Future<bool> getBoolSettingValue(int userId, String settingKey, {bool defaultValue = false}) async {
    try {
      return await _repository.getBoolSettingValue(userId, settingKey, defaultValue: defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }

  // Ayar değerini integer olarak al
  Future<int> getIntSettingValue(int userId, String settingKey, {int defaultValue = 0}) async {
    try {
      return await _repository.getIntSettingValue(userId, settingKey, defaultValue: defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }

  // Hata sıfırla
  void clearError() {
    if (state.hasError) {
      state = AsyncValue.data(state.value ?? []);
    }
  }

  // State'i yenile
  Future<void> refresh(int userId) async {
    await loadUserSettings(userId);
  }
}

// Yardımcı provider'lar
final currentUserSettingsNotifierProvider =
    StateNotifierProvider<CurrentUserSettingsNotifier, AsyncValue<List<UserSetting>>>((ref) {
  return CurrentUserSettingsNotifier(ref);
});

class CurrentUserSettingsNotifier extends StateNotifier<AsyncValue<List<UserSetting>>> {
  late UserSettingNotifier _settingNotifier;

  CurrentUserSettingsNotifier(Ref ref) : super(const AsyncValue.loading()) {
    _settingNotifier = ref.read(userSettingNotifierProvider.notifier);

    // Kullanıcı değiştiğinde ayarları yeniden yükle
    ref.listen(userNotifierProvider, (previous, next) {
      if (next.value != null) {
        loadSettings(next.value!.id!);
      } else {
        state = const AsyncValue.data([]);
      }
    });
  }

  Future<void> loadSettings(int userId) async {
    state = const AsyncValue.loading();
    try {
      final settings = await _settingNotifier._repository.getUserSettings(userId);

      // Eğer hiç ayar yoksa varsayılan ayarları oluştur
      if (settings.isEmpty) {
        await _settingNotifier._repository.createDefaultSettings(userId);
        final defaultSettings = await _settingNotifier._repository.getUserSettings(userId);
        state = AsyncValue.data(defaultSettings);
      } else {
        state = AsyncValue.data(settings);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSetting(UserSetting setting) async {
    await _settingNotifier.updateSetting(setting);
    // State'i yenile
    final currentUser = state.value?.first.userId;
    if (currentUser != null) {
      await loadSettings(currentUser);
    }
  }
}

// Kolay erişim için provider'lar
final userThemeProvider = Provider<String?>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return null;

  final themeSetting = settings.value!.firstWhere(
    (s) => s.settingKey == 'theme',
    orElse: () => UserSetting.themeSetting(userId: user.id!, theme: 'system'),
  );

  return themeSetting.settingValue ?? 'system';
});

final userLanguageProvider = Provider<String?>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return null;

  final languageSetting = settings.value!.firstWhere(
    (s) => s.settingKey == 'language',
    orElse: () => UserSetting.languageSetting(userId: user.id!, language: 'tr'),
  );

  return languageSetting.settingValue ?? 'tr';
});

final areNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return true;

  final setting = settings.value!.firstWhere(
    (s) => s.settingKey == 'notifications',
    orElse: () => UserSetting(
      userId: user.id!,
      settingKey: 'notifications',
      settingValue: 'true',
      category: SettingCategory.notifications,
      updatedAt: DateTime.now(),
    ),
  );

  return setting.getBoolValue();
});

final areEmailNotificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return true;

  final setting = settings.value!.firstWhere(
    (s) => s.settingKey == 'email_notifications',
    orElse: () => UserSetting.emailNotificationSetting(userId: user.id!, enabled: true),
  );

  return setting.getBoolValue();
});

final isAutoSyncEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return false;

  final setting = settings.value!.firstWhere(
    (s) => s.settingKey == 'auto_sync',
    orElse: () => UserSetting.autoSyncSetting(userId: user.id!, enabled: false),
  );

  return setting.getBoolValue();
});

final isAISummaryEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || settings.value == null) return true;

  final setting = settings.value!.firstWhere(
    (s) => s.settingKey == 'ai_summary',
    orElse: () => UserSetting.aiSummarySetting(userId: user.id!, enabled: true),
  );

  return setting.getBoolValue();
});
