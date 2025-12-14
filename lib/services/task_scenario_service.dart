import '../models/task.dart';
import '../models/email.dart';

/// Görev senaryoları servisi
/// Email içeriğine göre görev önceliklendirme ve kategorizasyon yapar
class TaskScenarioService {
  TaskScenarioService._internal();
  static final TaskScenarioService _instance = TaskScenarioService._internal();
  factory TaskScenarioService() => _instance;

  /// Email'den görev senaryosu belirle
  TaskScenario determineScenario({
    required Email email,
    Map<String, dynamic>? n8nResponse,
  }) {
    // Senaryo 1: Acil/Önemli email'lerden yüksek öncelikli görev
    if (_isUrgentEmail(email)) {
      return TaskScenario(
        priority: TaskPriority.urgent,
        category: TaskCategory.urgent,
        autoAssignDueDate: true,
        dueDateOffset: const Duration(days: 1),
        description: 'Acil email\'den otomatik oluşturuldu',
      );
    }

    // Senaryo 2: Toplantı davetleri -> Takvim ile entegre görev
    if (_isMeetingInvitation(email)) {
      return TaskScenario(
        priority: TaskPriority.high,
        category: TaskCategory.meeting,
        autoAssignDueDate: true,
        dueDateOffset: const Duration(days: 2),
        description: 'Toplantı davetinden otomatik oluşturuldu',
        shouldSyncWithCalendar: true,
      );
    }

    // Senaryo 3: Faturalar/Ödemeler -> Orta öncelik, son tarih önemli
    if (_isBillOrPayment(email)) {
      return TaskScenario(
        priority: TaskPriority.high,
        category: TaskCategory.finance,
        autoAssignDueDate: true,
        dueDateOffset: const Duration(days: 7),
        description: 'Fatura/ödeme email\'inden otomatik oluşturuldu',
      );
    }

    // Senaryo 4: Proje yönetimi email'leri -> Orta öncelik
    if (_isProjectManagement(email)) {
      return TaskScenario(
        priority: TaskPriority.medium,
        category: TaskCategory.project,
        autoAssignDueDate: false,
        description: 'Proje yönetimi email\'inden otomatik oluşturuldu',
      );
    }

    // Senaryo 5: Müşteri desteği -> Yüksek öncelik
    if (_isCustomerSupport(email)) {
      return TaskScenario(
        priority: TaskPriority.high,
        category: TaskCategory.support,
        autoAssignDueDate: true,
        dueDateOffset: const Duration(days: 3),
        description: 'Müşteri desteği email\'inden otomatik oluşturuldu',
      );
    }

    // Senaryo 6: n8n'den gelen özel senaryo
    if (n8nResponse != null) {
      final scenario = _extractScenarioFromN8n(n8nResponse);
      if (scenario != null) {
        return scenario;
      }
    }

    // Varsayılan senaryo
    return TaskScenario(
      priority: TaskPriority.medium,
      category: TaskCategory.general,
      autoAssignDueDate: false,
      description: 'Email\'den otomatik oluşturuldu',
    );
  }

  /// Acil email kontrolü
  bool _isUrgentEmail(Email email) {
    final subjectLower = email.subject.toLowerCase();
    final bodyLower = email.plainText?.toLowerCase() ?? '';

    final urgentKeywords = [
      'acil',
      'urgent',
      'asap',
      'hemen',
      'immediately',
      'critical',
      'kritik',
      'önemli',
      'important',
      '!!!',
      '🔥',
    ];

    for (final keyword in urgentKeywords) {
      if (subjectLower.contains(keyword) || bodyLower.contains(keyword)) {
        return true;
      }
    }

    // Önemli gönderenler
    final importantSenders = [
      'boss',
      'manager',
      'ceo',
      'director',
      'patron',
      'müdür',
    ];

    final fromLower = email.fromEmail.toLowerCase();
    for (final sender in importantSenders) {
      if (fromLower.contains(sender)) {
        return true;
      }
    }

    return false;
  }

  /// Toplantı daveti kontrolü
  bool _isMeetingInvitation(Email email) {
    final subjectLower = email.subject.toLowerCase();
    final bodyLower = email.plainText?.toLowerCase() ?? '';

    final meetingKeywords = [
      'meeting',
      'toplantı',
      'zoom',
      'teams',
      'google meet',
      'calendar',
      'takvim',
      'invitation',
      'davet',
      'rsvp',
    ];

    for (final keyword in meetingKeywords) {
      if (subjectLower.contains(keyword) || bodyLower.contains(keyword)) {
        return true;
      }
    }

    // .ics dosyası ekli mi?
    if (email.hasAttachments) {
      final attachments = email.attachments ?? [];
      for (final attachment in attachments) {
        final fileName = attachment.filename.toLowerCase();
        if (fileName.endsWith('.ics')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Fatura/Ödeme kontrolü
  bool _isBillOrPayment(Email email) {
    final subjectLower = email.subject.toLowerCase();
    final fromLower = email.fromEmail.toLowerCase();

    final billKeywords = [
      'invoice',
      'fatura',
      'bill',
      'ödeme',
      'payment',
      'billing',
      'faturalama',
      'receipt',
      'fiş',
      'statement',
      'ekstre',
    ];

    for (final keyword in billKeywords) {
      if (subjectLower.contains(keyword)) {
        return true;
      }
    }

    // Fatura gönderen domain'ler
    final billDomains = [
      'billing',
      'invoice',
      'payment',
      'paypal',
      'stripe',
      'bank',
      'banka',
    ];

    for (final domain in billDomains) {
      if (fromLower.contains(domain)) {
        return true;
      }
    }

    return false;
  }

  /// Proje yönetimi email kontrolü
  bool _isProjectManagement(Email email) {
    final subjectLower = email.subject.toLowerCase();
    final bodyLower = email.plainText?.toLowerCase() ?? '';

    final projectKeywords = [
      'project',
      'proje',
      'task',
      'görev',
      'milestone',
      'kilometre taşı',
      'deadline',
      'son tarih',
      'sprint',
      'jira',
      'trello',
      'asana',
    ];

    for (final keyword in projectKeywords) {
      if (subjectLower.contains(keyword) || bodyLower.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Müşteri desteği email kontrolü
  bool _isCustomerSupport(Email email) {
    final subjectLower = email.subject.toLowerCase();
    final fromLower = email.fromEmail.toLowerCase();

    final supportKeywords = [
      'support',
      'destek',
      'ticket',
      'bilet',
      'help',
      'yardım',
      'issue',
      'sorun',
      'problem',
      'complaint',
      'şikayet',
    ];

    for (final keyword in supportKeywords) {
      if (subjectLower.contains(keyword) || fromLower.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// n8n response'undan senaryo çıkar
  TaskScenario? _extractScenarioFromN8n(Map<String, dynamic> response) {
    if (response.containsKey('scenario') || response.containsKey('senaryo')) {
      final scenarioData = response['scenario'] ?? response['senaryo'];
      if (scenarioData is Map<String, dynamic>) {
        return TaskScenario.fromMap(scenarioData);
      }
    }
    return null;
  }
}

/// Görev senaryosu modeli
class TaskScenario {
  final TaskPriority priority;
  final TaskCategory category;
  final bool autoAssignDueDate;
  final Duration? dueDateOffset;
  final String description;
  final bool shouldSyncWithCalendar;

  TaskScenario({
    required this.priority,
    required this.category,
    required this.autoAssignDueDate,
    this.dueDateOffset,
    required this.description,
    this.shouldSyncWithCalendar = false,
  });

  factory TaskScenario.fromMap(Map<String, dynamic> map) {
    return TaskScenario(
      priority: TaskPriority.fromString(map['priority'] ?? 'medium'),
      category: TaskCategory.fromString(map['category'] ?? 'general'),
      autoAssignDueDate: map['auto_assign_due_date'] ?? false,
      dueDateOffset: map['due_date_offset'] != null
          ? Duration(days: map['due_date_offset'] as int)
          : null,
      description: map['description'] ?? '',
      shouldSyncWithCalendar: map['should_sync_with_calendar'] ?? false,
    );
  }

  DateTime? getDueDate() {
    if (!autoAssignDueDate || dueDateOffset == null) {
      return null;
    }
    return DateTime.now().add(dueDateOffset!);
  }
}

/// Görev kategorileri
enum TaskCategory {
  urgent,
  meeting,
  finance,
  project,
  support,
  general;

  String get displayName {
    switch (this) {
      case TaskCategory.urgent:
        return 'Acil';
      case TaskCategory.meeting:
        return 'Toplantı';
      case TaskCategory.finance:
        return 'Finans';
      case TaskCategory.project:
        return 'Proje';
      case TaskCategory.support:
        return 'Destek';
      case TaskCategory.general:
        return 'Genel';
    }
  }

  static TaskCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
      case 'acil':
        return TaskCategory.urgent;
      case 'meeting':
      case 'toplantı':
        return TaskCategory.meeting;
      case 'finance':
      case 'finans':
        return TaskCategory.finance;
      case 'project':
      case 'proje':
        return TaskCategory.project;
      case 'support':
      case 'destek':
        return TaskCategory.support;
      default:
        return TaskCategory.general;
    }
  }
}

