import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/providers/user_provider.dart';
import 'package:ai_asisstan/providers/user_setting_provider.dart';
import 'package:ai_asisstan/models/user_setting.dart';
import 'package:ai_asisstan/core/config/app_config.dart';
import '../data/mock_analytics.dart';
import '../data/analytics_repository.dart';

/// Analytics repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

/// Stat cards provider - gerçek veriden, kullanıcı yoksa SIFIR veriler
final statCardsProvider = FutureProvider.autoDispose((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    // Kullanıcı yoksa sadece sıfır değerler göster (mock yok)
    return MockAnalytics.statCards
        .map(
          (m) => StatCardData(
            title: m.title,
            mainValue: '0',
            subValue: m.subValue,
            trendValue: m.trendValue,
            icon: m.icon,
            color: m.color,
          ),
        )
        .toList();
  }

  // Kullanıcıya özel verimlilik hedefi (yoksa global default)
  final settings = ref.watch(currentUserSettingsNotifierProvider);
  int productivityTarget = AppConfig.productivityTarget;
  if (settings.value != null && settings.value!.isNotEmpty) {
    final setting = settings.value!.firstWhere(
      (s) => s.settingKey == 'productivity_target',
      orElse: () => UserSetting(
            userId: currentUser.id!,
            settingKey: 'productivity_target',
            settingValue: AppConfig.productivityTarget.toString(),
            category: SettingCategory.general,
            updatedAt: DateTime.now(),
          ),
    );
    productivityTarget = setting.getIntValue();
    if (productivityTarget <= 0) {
      productivityTarget = AppConfig.productivityTarget;
    }
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getStatCards(
    userId: currentUser.id!,
    productivityTarget: productivityTarget,
  );
});

/// Weekly tasks provider - son 7 gün, kullanıcı yoksa hepsi 0
final weeklyTasksProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    return {
      'Pzt': 0,
      'Sal': 0,
      'Çar': 0,
      'Per': 0,
      'Cum': 0,
      'Cmt': 0,
      'Paz': 0,
    };
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getWeeklyTasks(userId: currentUser.id!);
});

/// Weekly tasks detailed provider - tamamlanan ve toplam
final weeklyTasksDetailedProvider =
    FutureProvider.autoDispose<Map<String, Map<String, int>>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    // Kullanıcı yoksa her gün için completed/total = 0
    return {
      'Pzt': {'completed': 0, 'total': 0},
      'Sal': {'completed': 0, 'total': 0},
      'Çar': {'completed': 0, 'total': 0},
      'Per': {'completed': 0, 'total': 0},
      'Cum': {'completed': 0, 'total': 0},
      'Cmt': {'completed': 0, 'total': 0},
      'Paz': {'completed': 0, 'total': 0},
    };
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getWeeklyTasksDetailed(userId: currentUser.id!);
});

/// Email distribution provider - klasör bazlı dağılım, kullanıcı yoksa boş
final emailDistributionProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    return <String, int>{};
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getEmailDistribution(userId: currentUser.id!);
});

/// Monthly meetings provider - bu yıl için aylık toplantı sayıları, kullanıcı yoksa hepsi 0
final monthlyMeetingsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    return {
      'Oca': 0,
      'Şub': 0,
      'Mar': 0,
      'Nis': 0,
      'May': 0,
      'Haz': 0,
      'Tem': 0,
      'Ağu': 0,
      'Eyl': 0,
      'Eki': 0,
      'Kas': 0,
      'Ara': 0,
    };
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getMonthlyMeetings(userId: currentUser.id!);
});

/// Priority tasks provider - görev DURUMU bazlı dağılım, kullanıcı yoksa hepsi 0
final priorityTasksProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null || currentUser.id == null) {
    return {
      'Beklemede': 0,
      'Devam Ediyor': 0,
      'Tamamlandı': 0,
      'İptal Edildi': 0,
    };
  }

  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getPriorityTasks(userId: currentUser.id!);
});

