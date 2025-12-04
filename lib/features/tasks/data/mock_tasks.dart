import 'package:ai_asisstan/models/task.dart';

/// Mock görev verileri - Test ve geliştirme için
class MockTasks {
  static final List<Task> tasks = [
    Task(
      id: 1,
      userId: 1,
      title: 'Yeni proje sunumu hazırla',
      description: 'Müşteri için Q4 sunum dosyasını tamamla',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Task(
      id: 2,
      userId: 1,
      title: 'E-posta yanıtları',
      description: 'Gelen müşteri e-postalarını yanıtla',
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
      dueDate: DateTime.now().add(const Duration(hours: 4)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Task(
      id: 3,
      userId: 1,
      title: 'Kod incelemesi tamamla',
      description: 'Backend API kodlarını incele',
      status: TaskStatus.completed,
      priority: TaskPriority.low,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Duruma göre görevleri grupla
  static Map<TaskStatus, List<Task>> groupByStatus(List<Task> tasks) {
    return {
      TaskStatus.pending: tasks.where((task) => task.status == TaskStatus.pending).toList(),
      TaskStatus.inProgress: tasks.where((task) => task.status == TaskStatus.inProgress).toList(),
      TaskStatus.completed: tasks.where((task) => task.status == TaskStatus.completed).toList(),
    };
  }
}

