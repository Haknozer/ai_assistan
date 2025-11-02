import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/task.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';

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
  final List<Task> _mockTasks = [
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
    final tasks = _filteredTasks;
    return {
      TaskStatus.pending: tasks.where((task) => task.status == TaskStatus.pending).toList(),
      TaskStatus.inProgress: tasks.where((task) => task.status == TaskStatus.inProgress).toList(),
      TaskStatus.completed: tasks.where((task) => task.status == TaskStatus.completed).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
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
                    child: Row(
                      children: [
                        // Sayfa Başlığı
                        _buildPageHeader(),
                        const Spacer(),
                        // Görev Ekle Butonu
                        ElevatedButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add_task),
                          label: const Text('Görev Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arama ve Filtreleme
                  _buildSearchAndFilterSection(isDesktop: true),
                  const SizedBox(height: 24),

                  // Kanban Board
                  Expanded(
                    child: _buildKanbanBoard(isDesktop: true),
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
              child: Row(
                children: [
                  // Menu button
                  IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.menu),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  // Sayfa Başlığı
                  Expanded(
                    child: _buildPageHeader(),
                  ),
                  // Görev Ekle Butonu (Küçük)
                  IconButton.filled(
                    onPressed: _showAddTaskDialog,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),

            // Mobil İçerik
            Expanded(
              child: Padding(
                padding: padding.copyWith(top: 16),
                child: Column(
                  children: [
                    // Arama ve Filtreleme (Mobil)
                    _buildSearchAndFilterSection(isDesktop: false),
                    const SizedBox(height: 16),

                    // Kanban Board (Mobil)
                    Expanded(
                      child: _buildKanbanBoard(isDesktop: false),
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
            Navigator.pop(context); // Drawer'ı kapat
            _handleMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context); // Drawer'ı kapat
            _handleProfileTap();
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görev Yönetimi',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          'Görevlerinizi oluşturun, düzenleyin ve takip edin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection({required bool isDesktop}) {
    if (isDesktop) {
      // Desktop Layout - Yatay
      return Row(
        children: [
          // Arama Alanı
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Görev arama...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.getCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getBorderColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getBorderColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),

          // Filtreleme Butonları
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskFilter.values.map((filter) {
                  final isSelected = _currentFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _currentFilter = filter;
                        });
                      },
                      backgroundColor: AppColors.getCardColor(context),
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppColors.getPrimaryTextColor(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : AppColors.getBorderColor(context),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile Layout - Dikey
      return Column(
        children: [
          // Arama Alanı
          TextField(
            decoration: InputDecoration(
              hintText: 'Görev arama...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.getCardColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filtreleme Butonları
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _currentFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.getCardColor(context),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppColors.getPrimaryTextColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : AppColors.getBorderColor(context),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildKanbanBoard({required bool isDesktop}) {
    final tasksByStatus = _tasksByStatus;

    if (isDesktop) {
      // Desktop görünümü - Yatay kartlar
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: TaskStatus.values.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildKanbanColumn(status, tasks),
            ),
          );
        }).toList(),
      );
    } else {
      // Mobil görünümü - Dikey sütunlar
      return Column(
        children: TaskStatus.values.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildKanbanColumn(status, tasks),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildKanbanColumn(TaskStatus status, List<Task> tasks) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // Görev aynı sütuna bırakılırsa kabul etme
        return details.data.status != status;
      },
      onAcceptWithDetails: (details) {
        // Görevi yeni durum güncelle
        _updateTaskStatus(details.data, status);
      },
      onMove: (details) {
        // Hover efekti için
        setState(() {});
      },
      onLeave: (data) {
        // Hover'dan çıkınca normale dön
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? _getCardColor(status).withValues(alpha: 0.5)
                  : AppColors.getBorderColor(context).withValues(alpha: 0.5),
              width: isHovering ? 2 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: _getCardColor(status).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHovering
                      ? _getCardColor(status).withValues(alpha: 0.15)
                      : _getCardColor(status).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCardIcon(status),
                      color: _getCardColor(status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getCardColor(status),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCardColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color: _getCardColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isHovering) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_downward,
                        color: _getCardColor(status),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),

              // Tasks List
              Expanded(
                child: tasks.isEmpty
                    ? _buildEmptyColumn(status, isHovering)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTaskCard(task),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyColumn(TaskStatus status, bool isHovering) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCardIcon(status),
            size: isHovering ? 56 : 48,
            color: isHovering ? _getCardColor(status).withValues(alpha: 0.7) : Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            isHovering ? 'Görevi buraya bırakın' : 'Bu kategoride görev bulunmuyor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isHovering ? _getCardColor(status).withValues(alpha: 0.8) : Colors.grey,
                  fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          if (isHovering) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.arrow_downward,
              size: 20,
              color: _getCardColor(status).withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Container(
          width: 250, // Sürükleme sırasındaki genişlik
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _buildTaskCardContent(task, isDragging: true),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _buildTaskCardContent(task, isDragging: true),
      ),
      onDragStarted: () {
        // Sürükleme başladığında opacity düşür
        setState(() {});
      },
      onDragEnd: (details) {
        // Sürükleme bittiğinde opacity normale dön
        setState(() {});
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Task detail modal
          },
          child: _buildTaskCardContent(task),
        ),
      ),
    );
  }

  Widget _buildTaskCardContent(Task task, {bool isDragging = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sürükleme İkonu (sadece normal durumda)
          if (!isDragging) ...[
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sürükle bırak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Görev Başlığı ve Öncelik
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isDragging ? Colors.grey.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withValues(alpha: isDragging ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.displayName,
                  style: TextStyle(
                    color: _getPriorityColor(task.priority).withValues(alpha: isDragging ? 0.5 : 1),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Görev Açıklaması
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDragging
                        ? Colors.grey.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: isDragging ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Son Tarih
          if (task.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isDragging
                      ? Colors.grey.withValues(alpha: 0.4)
                      : (task.isOverdue ? AppTheme.errorColor : Colors.grey),
                ),
                const SizedBox(width: 4),
                Text(
                  task.formattedDueDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDragging
                            ? Colors.grey.withValues(alpha: 0.5)
                            : (task.isOverdue ? AppTheme.errorColor : Colors.grey),
                        fontWeight: task.isOverdue && !isDragging ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getCardColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppTheme.warningColor; // Turuncu - Yapılacak
      case TaskStatus.inProgress:
        return AppTheme.primaryColor; // Mavi - Devam Ediyor
      case TaskStatus.completed:
        return AppTheme.successColor; // Yeşil - Yapıldı
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getCardIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions;
      case TaskStatus.inProgress:
        return Icons.autorenew;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return const Color(0xFFD32F2F); // Kırmızı
      case TaskPriority.high:
        return AppTheme.errorColor; // Kırmızı
      case TaskPriority.medium:
        return AppTheme.warningColor; // Turuncu
      case TaskPriority.low:
        return AppTheme.successColor; // Yeşil
    }
  }

  void _handleMenuTap(int index) {
    if (index == 2) {
      // Görevler zaten buradayız, bir şey yapma
      return;
    }

    // Diğer menü öğelerine git
    switch (index) {
      case 0: // Ana Sayfa
        context.go('/home');
        break;
      case 1: // Birleşik Mesajlar
        context.go('/messages');
        break;
      case 3: // Takvim
        context.go('/calendar');
        break;
      case 4: // E-Posta
        context.go('/email');
        break;
      case 5: // Analitik
        context.go('/analytics');
        break;
      case 6: // AI Asistan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Asistan geliştiriliyor...')),
        );
        break;
      case 7: // Komut Paleti
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

  // Görev durumunu güncelle
  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    setState(() {
      // Görevi bul ve durumunu güncelle
      final taskIndex = _mockTasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _mockTasks[taskIndex] = _mockTasks[taskIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
    });

    // Küçük popup bildirim göster
    _showTaskUpdateNotification(task, newStatus);
  }

  // Küçük popup bildirim göster
  void _showTaskUpdateNotification(Task task, TaskStatus newStatus) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // Status bar altı
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _getCardColor(newStatus),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // İçerik
                Padding(
                  padding: const EdgeInsets.only(right: 32), // Kapatma butonu için yer bırak
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görev başlığı
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Durum güncelleme mesajı
                      Text(
                        'Projenizin durumu ${newStatus.displayName} olarak değiştirildi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kapatma butonu - sağ üstte
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      overlayEntry.remove();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 4 saniye sonra otomatik kapan
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  // Görev ekleme bildirimi göster
  void _showTaskAddedNotification(Task task) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // Status bar altı
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // İçerik
                Padding(
                  padding: const EdgeInsets.only(right: 32), // Kapatma butonu için yer bırak
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görev başlığı
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Başarı mesajı
                      const Text(
                        'Projeniz başarıyla eklendi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kapatma butonu - sağ üstte
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      overlayEntry.remove();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 4 saniye sonra otomatik kapan
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

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

// Görev Ekleme Dialog'u
class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.pending;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primaryColor,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null) {
        setState(() {
          _selectedDueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Yeni görev oluştur
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch, // Geçici ID
      userId: 1, // Geçici kullanıcı ID
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      status: _selectedStatus,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Callback ile görevi ekle
    widget.onTaskAdded(newTask);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                const Icon(
                  Icons.add_task,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yeni Görev Ekle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Görev Başlığı
                      Text(
                        'Görev Başlığı *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Görev başlığını girin...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Görev başlığı zorunludur';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Açıklama
                      Text(
                        'Açıklama',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Görev açıklamasını girin (opsiyonel)...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      // Öncelik Seçimi
                      Text(
                        'Öncelik',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: TaskPriority.values.map((priority) {
                          final isSelected = _selectedPriority == priority;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(priority.displayName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPriority = priority;
                                  });
                                },
                                backgroundColor: AppColors.getCardColor(context),
                                selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
                                checkmarkColor: _getPriorityColor(priority),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? _getPriorityColor(priority) : AppColors.getPrimaryTextColor(context),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected ? _getPriorityColor(priority) : AppColors.getBorderColor(context),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Durum Seçimi
                      Text(
                        'Durum',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskStatus>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: [
                                TaskStatus.pending,
                                TaskStatus.inProgress,
                                TaskStatus.completed,
                              ].map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Son Tarih
                      Text(
                        'Son Tarih',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDueDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.getBorderColor(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDueDate != null ? _formatDateTime(_selectedDueDate!) : 'Tarih seçin...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _selectedDueDate != null
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Colors.grey,
                                    ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.getBorderColor(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: AppColors.getBorderColor(context),
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Görev Ekle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return const Color(0xFFD32F2F);
      case TaskPriority.high:
        return AppTheme.errorColor;
      case TaskPriority.medium:
        return AppTheme.warningColor;
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }
}

// Filtreleme enum'u
enum TaskFilter {
  all('Tümü'),
  pending('Yapılacak'),
  inProgress('Devam Ediyor'),
  completed('Yapıldı');

  const TaskFilter(this.displayName);
  final String displayName;
}
