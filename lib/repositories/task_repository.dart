import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';
import '../models/task.dart';

class TaskRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  // Yeni görev oluştur
  Future<Task> createTask({
    required int userId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();

    final task = Task(
      userId: userId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      isCalendarSynced: false,
    );

    final id = await db.insert('tasks', task.toDatabase());
    return task.copyWith(id: id);
  }

  // ID'ye göre görev getir
  Future<Task?> getTaskById(int id) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Task.fromDatabase(maps.first);
  }

  // Kullanıcının tüm görevlerini getir
  Future<List<Task>> getTasksByUserId(int userId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromDatabase(map)).toList();
  }

  // Duruma göre görevleri getir
  Future<List<Task>> getTasksByStatus(int userId, TaskStatus status) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status.name],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromDatabase(map)).toList();
  }

  // Görev güncelle
  Future<int> updateTask(Task task) async {
    final db = await _databaseService.database;
    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    return await db.update(
      'tasks',
      updatedTask.toDatabase(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Görev durumunu güncelle
  Future<int> updateTaskStatus(int taskId, TaskStatus newStatus) async {
    final db = await _databaseService.database;

    return await db.update(
      'tasks',
      {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Görev önceliğini güncelle
  Future<int> updateTaskPriority(int taskId, TaskPriority newPriority) async {
    final db = await _databaseService.database;

    return await db.update(
      'tasks',
      {
        'priority': newPriority.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Görev başlığını ve açıklamasını güncelle
  Future<int> updateTaskDetails({
    required int taskId,
    String? title,
    String? description,
    DateTime? dueDate,
  }) async {
    final db = await _databaseService.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (dueDate != null) {
      updates['due_date'] = dueDate.toIso8601String();
    } else if (dueDate == null && description == null && title == null) {
      // Sadece dueDate'i null yapmak için
      updates['due_date'] = null;
    }

    return await db.update(
      'tasks',
      updates,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Görev sil
  Future<int> deleteTask(int taskId) async {
    final db = await _databaseService.database;

    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Kullanıcının tüm görevlerini sil
  Future<int> deleteAllTasksByUserId(int userId) async {
    final db = await _databaseService.database;

    return await db.delete(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Gecikmiş görevleri getir
  Future<List<Task>> getOverdueTasks(int userId) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND due_date < ? AND status != ?',
      whereArgs: [userId, now, TaskStatus.completed.name],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromDatabase(map)).toList();
  }

  // Yaklaşan görevleri getir (son tarih bugünden itibaren N gün içinde)
  Future<List<Task>> getUpcomingTasks(int userId, {int days = 7}) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days)).toIso8601String();
    final nowString = now.toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND due_date >= ? AND due_date <= ? AND status != ?',
      whereArgs: [userId, nowString, futureDate, TaskStatus.completed.name],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromDatabase(map)).toList();
  }

  // Arama fonksiyonu
  Future<List<Task>> searchTasks(int userId, String query) async {
    final db = await _databaseService.database;
    final searchQuery = '%$query%';

    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND (title LIKE ? OR description LIKE ?)',
      whereArgs: [userId, searchQuery, searchQuery],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromDatabase(map)).toList();
  }

  // Görev sayısını al
  Future<int> getTasksCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Duruma göre görev sayısını al
  Future<int> getTasksCountByStatus(int userId, TaskStatus status) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND status = ?',
      [userId, status.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Takvim senkronizasyon durumunu güncelle
  Future<int> updateCalendarSyncStatus(int taskId, bool isSynced) async {
    final db = await _databaseService.database;

    return await db.update(
      'tasks',
      {
        'is_calendar_synced': isSynced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}

