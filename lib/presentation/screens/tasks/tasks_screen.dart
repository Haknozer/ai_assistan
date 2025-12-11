import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../features/tasks/tasks_feature.dart';
import '../../widgets/tasks/tasks_page_header.dart';
import '../../widgets/tasks/search_and_filter_section.dart';
import '../../widgets/tasks/kanban_board.dart';
import '../../widgets/tasks/add_task_dialog.dart';
import '../../widgets/tasks/task_notification_overlay.dart';
import '../../widgets/command_palette/command_palette_dialog.dart';
import '../../../core/router/app_router.dart';

/// Görevler ekranı - Görev yönetimi ve Kanban board
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  // Filtreleme seçenekleri
  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';

  // Menu handler için
  final int _selectedMenuIndex = 2; // Görevler indeksi

  // Mock görev verileri (geçici)
  late List<Task> _mockTasks;

  @override
  void initState() {
    super.initState();
    _mockTasks = List.from(MockTasks.tasks);
  }

  // Filtrelenmiş görevleri döndürür
  List<Task> get _filteredTasks {
    List<Task> tasks = _mockTasks;

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

  // Duruma göre görevleri grupla
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

  // Desktop Layout - Sol menü + içerik
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
                    currentFilter: _currentFilter,
                    onFilterChanged: (filter) {
                      setState(() => _currentFilter = filter);
                    },
                    onSearchChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                    isDesktop: true,
                  ),
                  const SizedBox(height: 24),

                  // Kanban Board
                  Expanded(
                    child: KanbanBoard(
                      tasksByStatus: _tasksByStatus,
                      onTaskStatusChanged: _updateTaskStatus,
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

  // Mobile Layout - AppBar + Drawer + içerik
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding) {
    return Scaffold(
      appBar: AppBar(
        title: TasksPageHeader(
          onAddTask: _showAddTaskDialog,
          isDesktop: false,
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: padding.copyWith(top: 16),
          child: Column(
            children: [
              // Arama ve Filtreleme (Mobil)
              SearchAndFilterSection(
                currentFilter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() => _currentFilter = filter);
                },
                onSearchChanged: (query) {
                  setState(() => _searchQuery = query);
                },
                isDesktop: false,
              ),
              const SizedBox(height: 16),

              // Kanban Board (Mobil)
              Expanded(
                child: KanbanBoard(
                  tasksByStatus: _tasksByStatus,
                  onTaskStatusChanged: _updateTaskStatus,
                  isDesktop: false,
                ),
              ),
            ],
          ),
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
    if (index == 2) return; // Görevler zaten buradayız

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
        context.go('/ai-assistant');
        break;
      case 7:
        showCommandPaletteDialog(
          context,
          router: GoRouter.of(context),
          navigatorContext: rootNavigatorKey.currentContext,
        );
        break;
      case 8:
        context.go('/settings');
        break;
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  // Görev durumunu güncelle
  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    setState(() {
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _mockTasks[taskIndex] = _mockTasks[taskIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
    });

    // Bildirim göster
    _showTaskUpdateNotification(task, newStatus);
  }

  // Görev durumu güncelleme bildirimi
  void _showTaskUpdateNotification(Task task, TaskStatus newStatus) {
    TaskNotificationOverlay.show(
      context: context,
      task: task,
      message: 'Projenizin durumu ${newStatus.displayName} olarak değiştirildi',
      status: newStatus,
    );
  }

  // Görev ekleme bildirimi
  void _showTaskAddedNotification(Task task) {
    TaskNotificationOverlay.show(
      context: context,
      task: task,
      message: 'Projeniz başarıyla eklendi',
      status: null, // Başarı rengi
    );
  }

  // Görev ekleme dialog'unu göster
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: (task) {
          setState(() {
            _mockTasks.add(task);
          });
          Navigator.pop(context);
          _showTaskAddedNotification(task);
        },
      ),
    );
  }
}
