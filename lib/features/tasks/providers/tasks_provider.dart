import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/models/task.dart';
import '../../../repositories/task_repository.dart';
import '../../../providers/user_provider.dart';

/// Task repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Tasks listesi için StateNotifier
class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskRepository _repository;
  final int _userId;

  TasksNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getTasksByUserId(_userId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Görev listesini yenile
  Future<void> refresh() async {
    await _loadTasks();
  }

  /// Yeni görev oluştur
  Future<Task> createTask({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    try {
      final task = await _repository.createTask(
        userId: _userId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
      );

      // Optimistic update - yeni görevi listeye ekle
      final currentTasks = state.value ?? [];
      state = AsyncValue.data([...currentTasks, task]);

      return task;
    } catch (e) {
      debugPrint('createTask hatası: ${e.toString()}');
      // Hata durumunda listeyi yeniden yükle
      await refresh();
      rethrow;
    }
  }

  /// Görev güncelle
  Future<Task> updateTask(Task task) async {
    try {
      await _repository.updateTask(task);

      // Optimistic update - görevi güncelle
      final currentTasks = state.value ?? [];
      final updatedTasks = currentTasks.map((t) {
        if (t.id == task.id) {
          return task;
        }
        return t;
      }).toList();
      state = AsyncValue.data(updatedTasks);

      return task;
    } catch (e) {
      debugPrint('updateTask hatası: ${e.toString()}');
      // Hata durumunda listeyi yeniden yükle
      await refresh();
      rethrow;
    }
  }

  /// Görev durumunu güncelle
  Future<void> updateTaskStatus(int taskId, TaskStatus newStatus) async {
    try {
      await _repository.updateTaskStatus(taskId, newStatus);

      // Optimistic update - görev durumunu güncelle
      final currentTasks = state.value ?? [];
      final updatedTasks = currentTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        }
        return t;
      }).toList();
      state = AsyncValue.data(updatedTasks);
    } catch (e) {
      debugPrint('updateTaskStatus hatası: ${e.toString()}');
      // Hata durumunda listeyi yeniden yükle
      await refresh();
      rethrow;
    }
  }

  /// Görev sil
  Future<void> deleteTask(int taskId) async {
    try {
      // Optimistic update - görevi listeden çıkar
      final currentTasks = state.value ?? [];
      final updatedTasks = currentTasks.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(updatedTasks);

      await _repository.deleteTask(taskId);
    } catch (e) {
      debugPrint('deleteTask hatası: ${e.toString()}');
      // Hata durumunda listeyi yeniden yükle
      await refresh();
      rethrow;
    }
  }

  /// Görev ara
  Future<List<Task>> searchTasks(String query) async {
    try {
      return await _repository.searchTasks(_userId, query);
    } catch (e) {
      debugPrint('searchTasks hatası: ${e.toString()}');
      return [];
    }
  }
}

/// TasksNotifier provider
final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null || currentUser.id == null) {
    return TasksNotifier(repository, 0);
  }
  
  return TasksNotifier(repository, currentUser.id!);
});

/// Tasks grouped by status provider
final tasksGroupedByStatusProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  
  if (tasksAsync.value == null) {
    return {
      TaskStatus.pending: [],
      TaskStatus.inProgress: [],
      TaskStatus.completed: [],
      TaskStatus.cancelled: [],
    };
  }
  
  final tasks = tasksAsync.value!;
  final grouped = <TaskStatus, List<Task>>{};
  
  for (final status in TaskStatus.values) {
    grouped[status] = tasks.where((task) => task.status == status).toList();
  }
  
  return grouped;
});

/// Helper function to group tasks by status
Map<TaskStatus, List<Task>> groupTasksByStatus(List<Task> tasks) {
  final grouped = <TaskStatus, List<Task>>{};
  
  for (final status in TaskStatus.values) {
    grouped[status] = tasks.where((task) => task.status == status).toList();
  }
  
  return grouped;
}

