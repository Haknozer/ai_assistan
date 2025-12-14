import '../models/task.dart';
import '../models/email.dart';
import '../repositories/task_repository.dart';
import '../core/utils/logger.dart';
import 'task_scenario_service.dart';

/// Otomatik görev oluşturma servisi
/// n8n'den gelen response'ları analiz edip görevler oluşturur
class TaskAutoCreationService {
  TaskAutoCreationService._internal();
  static final TaskAutoCreationService _instance = TaskAutoCreationService._internal();
  factory TaskAutoCreationService() => _instance;

  final TaskRepository _taskRepository = TaskRepository();

  /// n8n response'undan görevleri çıkar ve oluştur
  /// 
  /// n8n response formatı örnekleri:
  /// 1. { "tasks": [{ "title": "...", "description": "...", "priority": "high", "due_date": "2024-01-01" }] }
  /// 2. { "task_extraction": { "tasks": [...] } }
  /// 3. { "extracted_tasks": [...] }
  Future<List<Task>> createTasksFromN8nResponse({
    required int userId,
    required Map<String, dynamic> n8nResponse,
    String? sourceEmailId,
    String? sourceEmailSubject,
    Email? sourceEmail,
  }) async {
    try {
      final extractedTasks = _extractTasksFromResponse(n8nResponse);
      
      if (extractedTasks.isEmpty) {
        AppLogger.debug('n8n response\'unda görev bulunamadı', 'TaskAutoCreation');
        return [];
      }

      final createdTasks = <Task>[];
      
      // Senaryo servisi ile görev önceliklendirme
      final scenarioService = TaskScenarioService();
      TaskScenario? scenario;
      if (sourceEmail != null) {
        scenario = scenarioService.determineScenario(
          email: sourceEmail,
          n8nResponse: n8nResponse,
        );
      }

      for (final taskData in extractedTasks) {
        try {
          final task = await _createTaskFromData(
            userId: userId,
            taskData: taskData,
            sourceEmailId: sourceEmailId,
            sourceEmailSubject: sourceEmailSubject,
            scenario: scenario,
          );
          
          if (task != null) {
            createdTasks.add(task);
            AppLogger.info(
              'Otomatik görev oluşturuldu: ${task.title} (Öncelik: ${task.priority.displayName})',
              'TaskAutoCreation',
            );
          }
        } catch (e) {
          AppLogger.error(
            'Görev oluşturulurken hata: ${taskData['title'] ?? 'Bilinmeyen'}',
            tag: 'TaskAutoCreation',
            error: e,
          );
        }
      }

      return createdTasks;
    } catch (e) {
      AppLogger.error(
        'n8n response\'undan görev çıkarılırken hata',
        tag: 'TaskAutoCreation',
        error: e,
      );
      return [];
    }
  }

  /// Email içeriğinden görev çıkar (AI analizi sonucu)
  /// 
  /// Email subject ve body'sinden görev bilgilerini çıkarır
  Future<Task?> createTaskFromEmail({
    required int userId,
    required String emailSubject,
    required String? emailBody,
    String? fromEmail,
    String? fromName,
    DateTime? receivedDate,
  }) async {
    try {
      // Email içeriğinden görev bilgilerini çıkar
      final taskInfo = _extractTaskInfoFromEmail(
        subject: emailSubject,
        body: emailBody ?? '',
        fromEmail: fromEmail,
        fromName: fromName,
      );

      if (taskInfo == null) {
        AppLogger.debug('Email\'den görev çıkarılamadı: $emailSubject', 'TaskAutoCreation');
        return null;
      }

      // Görevi oluştur
      final task = await _taskRepository.createTask(
        userId: userId,
        title: taskInfo['title'] as String,
        description: taskInfo['description'] as String?,
        status: taskInfo['status'] as TaskStatus? ?? TaskStatus.pending,
        priority: taskInfo['priority'] as TaskPriority? ?? TaskPriority.medium,
        dueDate: taskInfo['dueDate'] as DateTime?,
      );

      AppLogger.info(
        'Email\'den otomatik görev oluşturuldu: ${task.title}',
        'TaskAutoCreation',
      );

      return task;
    } catch (e) {
      AppLogger.error(
        'Email\'den görev oluşturulurken hata',
        tag: 'TaskAutoCreation',
        error: e,
      );
      return null;
    }
  }

  /// n8n response'undan görev verilerini çıkar
  List<Map<String, dynamic>> _extractTasksFromResponse(Map<String, dynamic> response) {
    final tasks = <Map<String, dynamic>>[];

    // Format 1: { "tasks": [...] }
    if (response.containsKey('tasks') && response['tasks'] is List) {
      final tasksList = response['tasks'] as List;
      for (final task in tasksList) {
        if (task is Map<String, dynamic>) {
          tasks.add(task);
        }
      }
    }

    // Format 2: { "task_extraction": { "tasks": [...] } }
    if (response.containsKey('task_extraction')) {
      final extraction = response['task_extraction'];
      if (extraction is Map<String, dynamic> && extraction.containsKey('tasks')) {
        final tasksList = extraction['tasks'] as List?;
        if (tasksList != null) {
          for (final task in tasksList) {
            if (task is Map<String, dynamic>) {
              tasks.add(task);
            }
          }
        }
      }
    }

    // Format 3: { "extracted_tasks": [...] }
    if (response.containsKey('extracted_tasks') && response['extracted_tasks'] is List) {
      final tasksList = response['extracted_tasks'] as List;
      for (final task in tasksList) {
        if (task is Map<String, dynamic>) {
          tasks.add(task);
        }
      }
    }

    // Format 4: { "gorevler": [...] } (Türkçe)
    if (response.containsKey('gorevler') && response['gorevler'] is List) {
      final tasksList = response['gorevler'] as List;
      for (final task in tasksList) {
        if (task is Map<String, dynamic>) {
          tasks.add(task);
        }
      }
    }

    // Format 5: Direkt görev objesi (tek görev)
    if (response.containsKey('title') || response.containsKey('gorev_basligi')) {
      tasks.add(response);
    }

    return tasks;
  }

  /// Görev verisinden Task oluştur
  Future<Task?> _createTaskFromData({
    required int userId,
    required Map<String, dynamic> taskData,
    String? sourceEmailId,
    String? sourceEmailSubject,
    TaskScenario? scenario,
  }) async {
    try {
      // Başlık çıkar (farklı key'ler için)
      final title = _extractString(taskData, [
        'title',
        'gorev_basligi',
        'baslik',
        'name',
        'task_title',
      ]);

      if (title == null || title.isEmpty) {
        AppLogger.debug('Görev başlığı bulunamadı', 'TaskAutoCreation');
        return null;
      }

      // Açıklama çıkar
      final description = _extractString(taskData, [
        'description',
        'aciklama',
        'desc',
        'task_description',
        'detay',
      ]);

      // Öncelik çıkar (senaryo varsa öncelik ver, yoksa taskData'dan)
      final priority = scenario?.priority ?? _extractPriority(taskData);

      // Durum çıkar
      final status = _extractStatus(taskData);

      // Son tarih çıkar (senaryo varsa senaryodan, yoksa taskData'dan)
      DateTime? dueDate = scenario?.getDueDate();
      if (dueDate == null) {
        dueDate = _extractDueDate(taskData);
      }

      // Email kaynağı bilgisini açıklamaya ekle
      String? finalDescription = description;
      if (sourceEmailSubject != null) {
        final emailInfo = '\n\n[Kaynak: $sourceEmailSubject]';
        finalDescription = (description ?? '') + emailInfo;
      }

      // Görevi oluştur
      final task = await _taskRepository.createTask(
        userId: userId,
        title: title,
        description: finalDescription?.isEmpty == true ? null : finalDescription,
        status: status,
        priority: priority,
        dueDate: dueDate,
      );

      return task;
    } catch (e) {
      AppLogger.error(
        'Görev verisinden Task oluşturulurken hata',
        tag: 'TaskAutoCreation',
        error: e,
      );
      return null;
    }
  }

  /// Email içeriğinden görev bilgilerini çıkar (basit pattern matching)
  Map<String, dynamic>? _extractTaskInfoFromEmail({
    required String subject,
    required String body,
    String? fromEmail,
    String? fromName,
  }) {
    // Görev belirteçleri
    final taskKeywords = [
      'görev',
      'task',
      'yapılacak',
      'todo',
      'action',
      'aksiyon',
      'önemli',
      'urgent',
      'acil',
      'hatırlat',
      'remind',
      'deadline',
      'son tarih',
      'due date',
    ];

    final subjectLower = subject.toLowerCase();
    final bodyLower = body.toLowerCase();

    // Subject veya body'de görev belirteci var mı?
    bool hasTaskKeyword = false;
    for (final keyword in taskKeywords) {
      if (subjectLower.contains(keyword) || bodyLower.contains(keyword)) {
        hasTaskKeyword = true;
        break;
      }
    }

    if (!hasTaskKeyword) {
      return null;
    }

    // Görev başlığı: Subject'i kullan veya body'den çıkar
    String taskTitle = subject;
    if (taskTitle.isEmpty || taskTitle.length < 3) {
      // Body'den ilk cümleyi al
      final firstSentence = body.split('.').first.trim();
      if (firstSentence.length > 10 && firstSentence.length < 100) {
        taskTitle = firstSentence;
      } else {
        taskTitle = 'Email\'den görev: ${subject.isNotEmpty ? subject : "Görev"}';
      }
    }

    // Öncelik belirleme
    TaskPriority priority = TaskPriority.medium;
    if (subjectLower.contains('acil') ||
        subjectLower.contains('urgent') ||
        subjectLower.contains('önemli') ||
        subjectLower.contains('important')) {
      priority = TaskPriority.high;
    }
    if (subjectLower.contains('çok acil') || subjectLower.contains('very urgent')) {
      priority = TaskPriority.urgent;
    }

    // Son tarih çıkar (basit pattern matching)
    DateTime? dueDate = _extractDateFromText(subject + ' ' + body);

    // Açıklama: Body'nin ilk 500 karakteri
    String? description = body.length > 500 ? body.substring(0, 500) + '...' : body;
    if (description.isEmpty) {
      description = null;
    }

    return {
      'title': taskTitle,
      'description': description,
      'priority': priority,
      'status': TaskStatus.pending,
      'dueDate': dueDate,
    };
  }

  /// String değer çıkar (farklı key'ler için)
  String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  /// Öncelik çıkar
  TaskPriority _extractPriority(Map<String, dynamic> data) {
    final priorityStr = _extractString(data, [
      'priority',
      'oncelik',
      'priority_level',
      'öncelik_seviyesi',
    ])?.toLowerCase();

    if (priorityStr == null) {
      return TaskPriority.medium;
    }

    switch (priorityStr) {
      case 'urgent':
      case 'acil':
      case 'çok acil':
      case '4':
        return TaskPriority.urgent;
      case 'high':
      case 'yüksek':
      case 'önemli':
      case '3':
        return TaskPriority.high;
      case 'low':
      case 'düşük':
      case '1':
        return TaskPriority.low;
      case 'medium':
      case 'orta':
      case '2':
      default:
        return TaskPriority.medium;
    }
  }

  /// Durum çıkar
  TaskStatus _extractStatus(Map<String, dynamic> data) {
    final statusStr = _extractString(data, [
      'status',
      'durum',
      'state',
    ])?.toLowerCase();

    if (statusStr == null) {
      return TaskStatus.pending;
    }

    switch (statusStr) {
      case 'in_progress':
      case 'devam ediyor':
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
      case 'tamamlandı':
      case 'done':
        return TaskStatus.completed;
      case 'cancelled':
      case 'iptal':
        return TaskStatus.cancelled;
      case 'pending':
      case 'beklemede':
      default:
        return TaskStatus.pending;
    }
  }

  /// Son tarih çıkar
  DateTime? _extractDueDate(Map<String, dynamic> data) {
    // ISO 8601 formatı
    final dueDateStr = _extractString(data, [
      'due_date',
      'dueDate',
      'son_tarih',
      'deadline',
      'bitis_tarihi',
    ]);

    if (dueDateStr != null) {
      try {
        return DateTime.parse(dueDateStr);
      } catch (e) {
        AppLogger.debug('Tarih parse edilemedi: $dueDateStr', 'TaskAutoCreation');
      }
    }

    // Unix timestamp
    if (data.containsKey('due_date_timestamp')) {
      final timestamp = data['due_date_timestamp'];
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    return null;
  }

  /// Metinden tarih çıkar (basit pattern matching)
  DateTime? _extractDateFromText(String text) {
    // Bugün, yarın, gelecek hafta gibi ifadeler
    final now = DateTime.now();
    final textLower = text.toLowerCase();

    if (textLower.contains('bugün') || textLower.contains('today')) {
      return now;
    }
    if (textLower.contains('yarın') || textLower.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    if (textLower.contains('gelecek hafta') || textLower.contains('next week')) {
      return now.add(const Duration(days: 7));
    }

    // Tarih formatları: DD.MM.YYYY, YYYY-MM-DD, vb.
    final datePatterns = [
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'), // 01.01.2024
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // 2024-01-01
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'), // 01/01/2024
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern == datePatterns[0]) {
            // DD.MM.YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (pattern == datePatterns[1]) {
            // YYYY-MM-DD
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (pattern == datePatterns[2]) {
            // MM/DD/YYYY veya DD/MM/YYYY (MM/DD/YYYY varsayalım)
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        } catch (e) {
          // Parse hatası, devam et
        }
      }
    }

    return null;
  }
}

