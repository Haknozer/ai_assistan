import 'package:ai_asisstan/core/database/database_service.dart';
import 'package:ai_asisstan/features/calendar/data/repositories/calendar_local_repository.dart';
import 'package:ai_asisstan/models/task.dart';
import 'package:ai_asisstan/models/calendar_event.dart';
import 'package:ai_asisstan/repositories/task_repository.dart';
import 'package:ai_asisstan/services/n8n_response_storage_service.dart';

import 'mock_analytics.dart';

/// Gerçek verilerden istatistik üreten repository
///
/// Not: Şu an için veriler local SQLite veritabanından hesaplanıyor.
/// İleride backend API hazır olduğunda bu katman sadece API'den gelen
/// hazır istatistikleri dönecek şekilde güncellenebilir.
class AnalyticsRepository {
  final DatabaseService _databaseService;
  final TaskRepository _taskRepository;
  final CalendarLocalRepository _calendarRepository;

  AnalyticsRepository({
    DatabaseService? databaseService,
    TaskRepository? taskRepository,
    CalendarLocalRepository? calendarRepository,
  })  : _databaseService = databaseService ?? DatabaseService.instance,
        _taskRepository = taskRepository ?? TaskRepository(),
        _calendarRepository = calendarRepository ?? CalendarLocalRepository();

  /// Dashboard üstündeki özet kartlar
  Future<List<StatCardData>> getStatCards({
    required int userId,
    required int productivityTarget,
  }) async {
    final now = DateTime.now();
    // Haftanın başlangıcı (Pazartesi 00:00)
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));

    // Görev istatistikleri (genel + bu hafta)
    final totalTasks = await _taskRepository.getTasksCount(userId);
    final completedTasks = await _taskRepository.getTasksCountByStatus(
      userId,
      TaskStatus.completed,
    );
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    // Bu haftaki görevler (created_at'e göre)
    final allTasks = await _taskRepository.getTasksByUserId(userId);
    final weeklyTasks = allTasks.where((task) {
      return task.createdAt.isAfter(weekStart.subtract(const Duration(milliseconds: 1))) &&
          task.createdAt.isBefore(weekEnd.add(const Duration(milliseconds: 1)));
    }).toList();
    final weeklyTotalTasks = weeklyTasks.length;
    final weeklyCompletedTasks =
        weeklyTasks.where((t) => t.status == TaskStatus.completed).length;

    // Toplantı istatistikleri (bu ay ve toplam) - sadece meeting türü
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth =
        now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final monthEnd = nextMonth.subtract(const Duration(milliseconds: 1));

    final monthlyEvents = await _calendarRepository.getEvents(
      userId: userId,
      timeMin: monthStart,
      timeMax: monthEnd,
    );
    // Sadece meeting türündeki event'leri say
    final monthlyMeetings = monthlyEvents
        .where((event) => event.eventType == EventType.meeting)
        .toList();

    // Bu haftaki toplantılar (haftalık verimlilik için)
    final weeklyEvents = await _calendarRepository.getEvents(
      userId: userId,
      timeMin: weekStart,
      timeMax: weekEnd,
    );
    final meetingsThisWeek = weeklyEvents
        .where((event) => event.eventType == EventType.meeting)
        .toList();

    final allEvents = await _calendarRepository.getEvents(userId: userId);
    final totalMeetings = allEvents
        .where((event) => event.eventType == EventType.meeting)
        .length;

    // Email istatistikleri (bu hafta ve önemli / yıldızlı)
    final db = await _databaseService.database;

    // 1) Önce n8n response storage üzerinden say (n8n'e gönderilmiş mailler)
    final nowUtc = now.toUtc();
    final weekStartUtc = weekStart.toUtc();

    final n8nResponses = await N8nResponseStorageService()
        .getEmailResponsesByDateRange(startUtc: weekStartUtc, endUtc: nowUtc);

    int weeklyEmails;

    if (n8nResponses.isNotEmpty) {
      // Son 7 günde n8n'e gitmiş mailler
      weeklyEmails = n8nResponses.length;
    } else {
      // 2) Fallback: emails tablosundan say (tüm mailler)
      final weekStartIso = weekStart.toIso8601String();

      // received_date boş olabilir; bu durumda sent_date / created_at kullan
      final weeklyEmailsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM emails '
        'WHERE user_id = ? '
        'AND COALESCE(received_date, sent_date, created_at) >= ? '
        'AND is_deleted = 0 '
        'AND is_spam = 0',
        [userId, weekStartIso],
      );
      weeklyEmails = (weeklyEmailsResult.first['count'] as int?) ?? 0;
    }

    final importantEmailsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM emails '
      'WHERE user_id = ? AND (is_starred = 1 OR email_importance > 0) AND is_deleted = 0',
      [userId],
    );
    final importantEmails =
        (importantEmailsResult.first['count'] as int?) ?? 0;

    // Bu haftaya göre verimlilik skoru (0-100)
    // Görevler: haftalık tamamlama oranı
    double weeklyTaskScore;
    if (weeklyTotalTasks > 0) {
      weeklyTaskScore = weeklyCompletedTasks / weeklyTotalTasks;
    } else if (totalTasks > 0) {
      weeklyTaskScore = completedTasks / totalTasks; // genel oran fallback
    } else {
      weeklyTaskScore = 0.0;
    }

    // Toplantılar: hedef 5 toplantı/hafta (0-1 arası normalize)
    const meetingTargetPerWeek = 5;
    final weeklyMeetingsCount = meetingsThisWeek.length;
    final meetingScore =
        (weeklyMeetingsCount / meetingTargetPerWeek).clamp(0.0, 1.0);

    // E-posta: hedef 50 email/hafta (0-1 arası normalize)
    const emailTargetPerWeek = 50;
    final emailScore = (weeklyEmails / emailTargetPerWeek).clamp(0.0, 1.0);

    final productivity = ((weeklyTaskScore * 0.5) +
            (meetingScore * 0.25) +
            (emailScore * 0.25)) *
        100;
    final productivityRounded = productivity.clamp(0, 100).round();

    return [
      StatCardData(
        title: 'Tamamlanan Görevler',
        mainValue: completedTasks.toString(),
        subValue: '$totalTasks görevden',
        trendValue: '%$completionRate Tamamlandı',
        icon: MockAnalytics.statCards[0].icon,
        color: MockAnalytics.statCards[0].color,
      ),
      StatCardData(
        title: 'Toplantılar',
        mainValue: 'Bu ay ${monthlyMeetings.length}',
        subValue: 'Toplamda $totalMeetings',
        trendValue: monthlyMeetings.isNotEmpty ? '+${monthlyMeetings.length} bu ay' : 'Bu ay toplantı yok',
        icon: MockAnalytics.statCards[1].icon,
        color: MockAnalytics.statCards[1].color,
      ),
      StatCardData(
        title: 'E-posta',
        mainValue: weeklyEmails.toString(),
        subValue: 'Son 7 gün',
        trendValue: '$importantEmails önemli',
        icon: MockAnalytics.statCards[2].icon,
        color: MockAnalytics.statCards[2].color,
      ),
      StatCardData(
        title: 'Verimlilik Skoru',
        mainValue: '$productivityRounded%',
        subValue: 'Bu hafta',
        trendValue: productivityRounded >= productivityTarget
            ? '${productivityRounded - productivityTarget}% hedefin üzerinde'
            : '${productivityTarget - productivityRounded}% hedefin altında',
        icon: MockAnalytics.statCards[3].icon,
        color: MockAnalytics.statCards[3].color,
      ),
    ];
  }

  /// Haftalık görev istatistikleri (Pzt-Paz)
  Future<Map<String, int>> getWeeklyTasks({required int userId}) async {
    final tasks = await _taskRepository.getTasksByUserId(userId);
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6)); // Son 7 gün

    final result = <String, int>{
      'Pzt': 0,
      'Sal': 0,
      'Çar': 0,
      'Per': 0,
      'Cum': 0,
      'Cmt': 0,
      'Paz': 0,
    };

    for (final task in tasks) {
      if (task.status != TaskStatus.completed) continue;
      if (task.updatedAt.isBefore(weekStart) || task.updatedAt.isAfter(now)) {
        continue;
      }
      final weekday = task.updatedAt.weekday; // 1 = Pazartesi ... 7 = Pazar
      switch (weekday) {
        case DateTime.monday:
          result['Pzt'] = (result['Pzt'] ?? 0) + 1;
          break;
        case DateTime.tuesday:
          result['Sal'] = (result['Sal'] ?? 0) + 1;
          break;
        case DateTime.wednesday:
          result['Çar'] = (result['Çar'] ?? 0) + 1;
          break;
        case DateTime.thursday:
          result['Per'] = (result['Per'] ?? 0) + 1;
          break;
        case DateTime.friday:
          result['Cum'] = (result['Cum'] ?? 0) + 1;
          break;
        case DateTime.saturday:
          result['Cmt'] = (result['Cmt'] ?? 0) + 1;
          break;
        case DateTime.sunday:
          result['Paz'] = (result['Paz'] ?? 0) + 1;
          break;
      }
    }

    return result;
  }

  /// Haftalık görev istatistikleri (tamamlanan ve toplam) - Pzt-Paz
  /// Map['Pzt'] = {'completed': x, 'total': y}
  Future<Map<String, Map<String, int>>> getWeeklyTasksDetailed({
    required int userId,
  }) async {
    final tasks = await _taskRepository.getTasksByUserId(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd =
        weekStart.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));

    final result = <String, Map<String, int>>{
      'Pzt': {'completed': 0, 'total': 0},
      'Sal': {'completed': 0, 'total': 0},
      'Çar': {'completed': 0, 'total': 0},
      'Per': {'completed': 0, 'total': 0},
      'Cum': {'completed': 0, 'total': 0},
      'Cmt': {'completed': 0, 'total': 0},
      'Paz': {'completed': 0, 'total': 0},
    };

    for (final task in tasks) {
      // 1) TOPLAM: Görevin due date'ine göre dağıt (yoksa createdAt)
      final dueOrCreated = task.dueDate ?? task.createdAt;
      if (dueOrCreated.isAfter(weekEnd) || dueOrCreated.isBefore(weekStart)) {
        // Bu haftanın dışında planlanmış görev
      } else {
        final weekdayTotal = dueOrCreated.weekday; // 1 = Pazartesi ... 7 = Pazar
        String? keyTotal;
        switch (weekdayTotal) {
          case DateTime.monday:
            keyTotal = 'Pzt';
            break;
          case DateTime.tuesday:
            keyTotal = 'Sal';
            break;
          case DateTime.wednesday:
            keyTotal = 'Çar';
            break;
          case DateTime.thursday:
            keyTotal = 'Per';
            break;
          case DateTime.friday:
            keyTotal = 'Cum';
            break;
          case DateTime.saturday:
            keyTotal = 'Cmt';
            break;
          case DateTime.sunday:
            keyTotal = 'Paz';
            break;
        }

        if (keyTotal != null) {
          final dayMap = result[keyTotal]!;
          dayMap['total'] = (dayMap['total'] ?? 0) + 1;
        }
      }

      // 2) TAMAMLANAN: updatedAt'e göre dağıt (yalnızca completed görevler)
      if (task.status != TaskStatus.completed) {
        continue;
      }
      if (task.updatedAt.isBefore(weekStart) || task.updatedAt.isAfter(weekEnd)) {
        continue;
      }

      final weekdayCompleted = task.updatedAt.weekday; // 1 = Pazartesi ... 7 = Pazar
      String? key;
      switch (weekdayCompleted) {
        case DateTime.monday:
          key = 'Pzt';
          break;
        case DateTime.tuesday:
          key = 'Sal';
          break;
        case DateTime.wednesday:
          key = 'Çar';
          break;
        case DateTime.thursday:
          key = 'Per';
          break;
        case DateTime.friday:
          key = 'Cum';
          break;
        case DateTime.saturday:
          key = 'Cmt';
          break;
        case DateTime.sunday:
          key = 'Paz';
          break;
      }

      if (key == null) continue;

      final dayMap = result[key]!;
      dayMap['total'] = (dayMap['total'] ?? 0) + 1;
      if (task.status == TaskStatus.completed) {
        dayMap['completed'] = (dayMap['completed'] ?? 0) + 1;
      }
    }

    return result;
  }

  /// E-posta kategori dağılımı
  ///
  /// n8n response'larındaki category bilgisine göre:
  /// Görev / Toplantı / Staj / Reklam / Diğer
  Future<Map<String, int>> getEmailDistribution({required int userId}) async {
    final n8nService = N8nResponseStorageService();
    
    // Tüm zamanlar için n8n response'larını al (çok geniş tarih aralığı)
    final allTimeStart = DateTime(2000, 1, 1, 0, 0, 0, 0, 0);
    final allTimeEnd = DateTime(2100, 12, 31, 23, 59, 59, 999, 999);
    final n8nResponses = await n8nService.getEmailResponsesByDateRange(
      startUtc: allTimeStart.toUtc(),
      endUtc: allTimeEnd.toUtc(),
    );

    // Kategori sayıları
    final categories = <String, int>{
      'Görev': 0,
      'Toplantı': 0,
      'Staj': 0,
      'Reklam': 0,
      'Diğer': 0,
    };

    // Her n8n response'dan category bilgisini çıkar
    for (final responseData in n8nResponses) {
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) continue;

      // Response formatı: array içinde olabilir veya direkt map olabilir
      dynamic categoryData = data;
      
      // Eğer _isArray flag'i varsa, arrayData'yı al
      if (data.containsKey('_isArray') && data['_isArray'] == true) {
        final arrayData = data['_arrayData'];
        if (arrayData is List && arrayData.isNotEmpty) {
          // İlk elemandan category'yi al
          categoryData = arrayData[0];
        }
      }
      
      // Array formatında gelebilir: [{category: "...", ...}]
      if (categoryData is List && categoryData.isNotEmpty) {
        categoryData = categoryData[0];
      }

      String? category;
      if (categoryData is Map<String, dynamic>) {
        // Direkt category alanı varsa
        category = categoryData['category']?.toString().toLowerCase().trim();
        
        // Eğer category yoksa, event'lerden çıkarabiliriz
        if (category == null || category.isEmpty) {
          final events = categoryData['events'] ?? categoryData['cevap'];
          if (events is List && events.isNotEmpty) {
            final firstEvent = events[0];
            if (firstEvent is Map<String, dynamic>) {
              category = firstEvent['category']?.toString().toLowerCase().trim();
            }
          }
        }
      }

      // Kategoriyi normalize et
      final normalizedCategory = _normalizeCategory(category);
      categories[normalizedCategory] = (categories[normalizedCategory] ?? 0) + 1;
    }

    return categories;
  }

  /// n8n'den gelen category string'ini Türkçe kategoriye çevir
  String _normalizeCategory(String? category) {
    if (category == null || category.isEmpty) {
      return 'Diğer';
    }

    final lower = category.toLowerCase().trim();
    
    // Görev kategorileri
    if (lower == 'task' || lower == 'görev' || lower == 'gorev') {
      return 'Görev';
    }
    
    // Toplantı kategorileri
    if (lower == 'meeting' || lower == 'toplantı' || lower == 'toplanti') {
      return 'Toplantı';
    }
    
    // Staj kategorileri
    if (lower == 'internship' || lower == 'staj' || lower == 'stajyer') {
      return 'Staj';
    }
    
    // Reklam kategorileri
    if (lower == 'ad' || lower == 'promo' || lower == 'reklam' || 
        lower == 'advertisement' || lower == 'marketing' || lower == 'spam') {
      return 'Reklam';
    }
    
    // Diğer her şey
    return 'Diğer';
  }

  /// Bu yıl içindeki aylara göre toplantı sayıları
  Future<Map<String, int>> getMonthlyMeetings({required int userId}) async {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    final events = await _calendarRepository.getEvents(
      userId: userId,
      timeMin: yearStart,
      timeMax: yearEnd,
    );
    // Sadece meeting türündeki event'leri dikkate al
    final meetingEvents =
        events.where((event) => event.eventType == EventType.meeting);

    final months = <String, int>{
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

    for (final event in meetingEvents) {
      final month = event.startTime.month;
      switch (month) {
        case 1:
          months['Oca'] = (months['Oca'] ?? 0) + 1;
          break;
        case 2:
          months['Şub'] = (months['Şub'] ?? 0) + 1;
          break;
        case 3:
          months['Mar'] = (months['Mar'] ?? 0) + 1;
          break;
        case 4:
          months['Nis'] = (months['Nis'] ?? 0) + 1;
          break;
        case 5:
          months['May'] = (months['May'] ?? 0) + 1;
          break;
        case 6:
          months['Haz'] = (months['Haz'] ?? 0) + 1;
          break;
        case 7:
          months['Tem'] = (months['Tem'] ?? 0) + 1;
          break;
        case 8:
          months['Ağu'] = (months['Ağu'] ?? 0) + 1;
          break;
        case 9:
          months['Eyl'] = (months['Eyl'] ?? 0) + 1;
          break;
        case 10:
          months['Eki'] = (months['Eki'] ?? 0) + 1;
          break;
        case 11:
          months['Kas'] = (months['Kas'] ?? 0) + 1;
          break;
        case 12:
          months['Ara'] = (months['Ara'] ?? 0) + 1;
          break;
      }
    }

    return months;
  }

  /// Görev DURUMU bazlı dağılım (Beklemede / Devam Ediyor / Tamamlandı / İptal Edildi)
  Future<Map<String, int>> getPriorityTasks({required int userId}) async {
    final tasks = await _taskRepository.getTasksByUserId(userId);
    final result = <String, int>{
      'Beklemede': 0,
      'Devam Ediyor': 0,
      'Tamamlandı': 0,
      'İptal Edildi': 0,
    };

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.pending:
          result['Beklemede'] = (result['Beklemede'] ?? 0) + 1;
          break;
        case TaskStatus.inProgress:
          result['Devam Ediyor'] = (result['Devam Ediyor'] ?? 0) + 1;
          break;
        case TaskStatus.completed:
          result['Tamamlandı'] = (result['Tamamlandı'] ?? 0) + 1;
          break;
        case TaskStatus.cancelled:
          result['İptal Edildi'] = (result['İptal Edildi'] ?? 0) + 1;
          break;
      }
    }

    return result;
  }
}


