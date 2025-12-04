import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_asisstan/models/task.dart';
import '../data/mock_tasks.dart';

/// Tasks list provider - Mock data için
final tasksProvider = Provider<List<Task>>((ref) {
  return MockTasks.tasks;
});

/// Tasks grouped by status provider
final tasksGroupedByStatusProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return MockTasks.groupByStatus(tasks);
});

