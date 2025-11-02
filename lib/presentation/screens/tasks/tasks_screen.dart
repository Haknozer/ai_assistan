import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/task.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import 'data/mock_tasks.dart';
import 'utils/task_filter.dart';
import '../../widgets/tasks/tasks_page_header.dart';
import '../../widgets/tasks/search_and_filter_section.dart';
import '../../widgets/tasks/kanban_board.dart';
import '../../widgets/tasks/add_task_dialog.dart';
import '../../widgets/tasks/task_notification_overlay.dart';

/// Görev yönetimi ekranı - Kanban board ile görev takibi
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  final int _selectedMenuIndex = 2;

  // Mock görev verileri
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(MockTasks.tasks);
  }

  /// Filtrelenmiş görevleri döndürür
  List<Task> get _filteredTasks {
    List<Task> tasks = _tasks;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Durum filtresi
    switch (_currentFilter) {
      case TaskFilter.pending:
        return tasks.where((task) => task.status == TaskStatus.pending).toList();
      case TaskFilter.inProgress:
        return tasks.where((task) => task.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.status == TaskStatus.completed).toList();
      case TaskFilter.all:
        return tasks;
    }
  }

  /// Duruma göre görevleri grupla
  Map<TaskStatus, List<Task>> get _tasksByStatus {
    return MockTasks.groupByStatus(_filteredTasks);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(currentUser, padding, isDesktop),
    );
  }

  Widget _buildResponsiveLayout(dynamic currentUser, EdgeInsets padding, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, padding);
    } else {
      return _buildMobileLayout(currentUser, padding);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(dynamic currentUser, EdgeInsets padding) {
    return Row(
      children: [
        // Sol Menü
        SizedBox(
          width: 280,
          child: SideMenu(
            userName: currentUser.name,
            userEmail: currentUser.email,
            selectedIndex: _selectedMenuIndex,
            onMenuTap: _handleMenuTap,
            onProfileTap: _handleProfileTap,
          ),
        ),
        // Ana İçerik Alanı
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sayfa Başlığı ve Görev Ekle Butonu
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TasksPageHeader(
                      onAddTask: _showAddTaskDialog,
                      isDesktop: true,
                    ),
                  ),

                  // Arama ve Filtreleme
                  SearchAndFilterSection(
                    onSearchChanged: (query) => setState(() => _searchQuery = query),
                    currentFilter: _currentFilter,
                    onFilterChanged: (filter) => setState(() => _currentFilter = filter),
                    isDesktop: true,
                  ),
                  const SizedBox(height: 24),

                  // Kanban Board
                  Expanded(
                    child: KanbanBoard(
                      tasksByStatus: _tasksByStatus,
                      onTaskMoved: _updateTaskStatus,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout - AppBar + Drawer + içerik
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Mobil AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                ),
              ),
              child: TasksPageHeader(
                onAddTask: _showAddTaskDialog,
                isDesktop: false,
              ),
            ),

            // Mobil İçerik
            Expanded(
              child: Padding(
                padding: padding.copyWith(top: 16),
                child: Column(
                  children: [
                    SearchAndFilterSection(
                      onSearchChanged: (query) => setState(() => _searchQuery = query),
                      currentFilter: _currentFilter,
                      onFilterChanged: (filter) => setState(() => _currentFilter = filter),
                      isDesktop: false,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: KanbanBoard(
                        tasksByStatus: _tasksByStatus,
                        onTaskMoved: _updateTaskStatus,
                        isDesktop: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: _selectedMenuIndex,
          onMenuTap: (index) {
            Navigator.pop(context);
            _handleMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context);
            _handleProfileTap();
          },
        ),
      ),
    );
  }

  void _handleMenuTap(int index) {
    if (index == 2) return; // Zaten görevler sayfasındayız

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/messages');
        break;
      case 3:
        context.go('/calendar');
        break;
      case 4:
        context.go('/email');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 6:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Asistan geliştiriliyor...')),
        );
        break;
      case 7:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  /// Görev durumunu güncelle
  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    setState(() {
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
    });

    TaskNotificationOverlay.showTaskUpdateNotification(context, task, newStatus);
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (task) {
          setState(() => _tasks.add(task));
          Navigator.pop(context);
          TaskNotificationOverlay.showTaskAddedNotification(context, task);
        },
      ),
    );
  }
}
