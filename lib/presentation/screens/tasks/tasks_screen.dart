import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../features/tasks/tasks_feature.dart';
import '../../../features/tasks/providers/tasks_provider.dart';
import '../../widgets/tasks/tasks_page_header.dart';
import '../../widgets/tasks/search_and_filter_section.dart';
import '../../widgets/tasks/kanban_board.dart';
import '../../widgets/tasks/add_task_dialog.dart';
import '../../widgets/tasks/task_notification_overlay.dart';
import '../../widgets/tasks/trash_bin_widget.dart';
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

  // Filtrelenmiş görevleri döndürür
  List<Task> _getFilteredTasks(List<Task> tasks) {
    List<Task> filtered = tasks;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Durum filtresi
    switch (_currentFilter) {
      case TaskFilter.pending:
        return filtered.where((task) => task.status == TaskStatus.pending).toList();
      case TaskFilter.inProgress:
        return filtered.where((task) => task.status == TaskStatus.inProgress).toList();
      case TaskFilter.completed:
        return filtered.where((task) => task.status == TaskStatus.completed).toList();
      case TaskFilter.all:
        return filtered;
    }
  }

  // Duruma göre görevleri grupla
  Map<TaskStatus, List<Task>> _getTasksByStatus(List<Task> tasks) {
    final filtered = _getFilteredTasks(tasks);
    return groupTasksByStatus(filtered);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: tasksAsync.when(
        data: (tasks) => _buildResponsiveLayout(currentUser, padding, isDesktop, tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(tasksNotifierProvider.notifier).refresh(),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(dynamic currentUser, EdgeInsets padding, bool isDesktop, List<Task> tasks) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, padding, tasks);
    } else {
      return _buildMobileLayout(currentUser, padding, tasks);
    }
  }

  // Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(dynamic currentUser, EdgeInsets padding, List<Task> tasks) {
    final tasksByStatus = _getTasksByStatus(tasks);
    
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
                    child: Column(
                      children: [
                        Expanded(
                          child: KanbanBoard(
                            tasksByStatus: tasksByStatus,
                            onTaskStatusChanged: _updateTaskStatus,
                            isDesktop: true,
                          ),
                        ),
                        // Çöp Kutusu (Alt taraf - Desktop)
                        TrashBinWidget(
                          onTaskDropped: _deleteTask,
                        ),
                      ],
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
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding, List<Task> tasks) {
    final tasksByStatus = _getTasksByStatus(tasks);
    
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
                child: Column(
                  children: [
                    Expanded(
                      child: KanbanBoard(
                        tasksByStatus: tasksByStatus,
                        onTaskStatusChanged: _updateTaskStatus,
                        isDesktop: false,
                      ),
                    ),
                    // Çöp Kutusu (Alt taraf - Mobil)
                    TrashBinWidget(
                      onTaskDropped: _deleteTask,
                    ),
                  ],
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
  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    if (task.id == null) return;
    
    try {
      await ref.read(tasksNotifierProvider.notifier).updateTaskStatus(task.id!, newStatus);
      // Bildirim göster
      _showTaskUpdateNotification(task, newStatus);
    } catch (e) {
      // Hata durumunda kullanıcıya bildir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev durumu güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Görev sil
  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;
    
    try {
      await ref.read(tasksNotifierProvider.notifier).deleteTask(task.id!);
      
      // Başarı bildirimi göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${task.title}" görevi silindi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bildir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        onTaskAdded: (task) async {
          try {
            final currentUser = ref.read(currentUserProvider);
            if (currentUser == null || currentUser.id == null) {
              throw Exception('Kullanıcı bulunamadı');
            }
            
            // Repository üzerinden görev oluştur
            final createdTask = await ref.read(tasksNotifierProvider.notifier).createTask(
              title: task.title,
              description: task.description,
              status: task.status,
              priority: task.priority,
              dueDate: task.dueDate,
            );
            
            if (mounted) {
              Navigator.pop(context);
              _showTaskAddedNotification(createdTask);
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Görev eklenirken hata oluştu: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
