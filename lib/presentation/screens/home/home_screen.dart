import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/home/desktop_layout.dart';
import '../../widgets/home/mobile_layout.dart';
import '../../widgets/home/loading_widget.dart';
import '../../widgets/circle_avatar_with_initials.dart';
import 'dashboard_page.dart';
import '../tasks/tasks_screen.dart';
import '../calendar/calendar_screen.dart';
import '../email/email_screen.dart';
import '../analytics/analytics_screen.dart';
import '../messages/unified_messages_screen.dart';
import '../../widgets/command_palette/command_palette_dialog.dart';
import '../../../core/router/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const UnifiedMessagesScreen(), // Birleşik Mesajlar
    const TasksScreen(),
    const CalendarScreen(),
    const EmailScreen(),
    const AnalyticsScreen(),
    Container(), // AI Asistan
    const SizedBox.shrink(), // Komut Paleti artık popup
    // Karanlık Mod bir sayfa değil, sadece toggle işlemi yapılıyor
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const LoadingWidget();
    }

    return ResponsiveUtils.isDesktop(context)
        ? DesktopLayout(
            currentUser: currentUser,
            selectedIndex: _selectedIndex,
            pages: _pages,
            onMenuTap: (index) {
              if (index == 7) {
                _handleNavigation(index);
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
              _handleNavigation(index);
            },
            onProfileTap: _handleProfileTap,
          )
        : Scaffold(
            drawer: _buildDrawer(context, currentUser),
            body: MobileLayout(
              currentUser: currentUser,
              selectedIndex: _selectedIndex,
              pages: _pages,
              onMenuTap: (index) {
                if (index == 7) {
                  _handleNavigation(index);
                  return;
                }
                setState(() {
                  _selectedIndex = index;
                });
                _handleNavigation(index);
              },
              onProfileTap: _handleProfileTap,
              onNotificationsPressed: _handleNotificationsPressed,
            ),
          );
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  void _handleNotificationsPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirimler')),
    );
  }

  Widget _buildDrawer(BuildContext context, currentUser) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header - Kullanıcı Profili
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser?.name ?? 'Kullanıcı',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              currentUser?.email ?? 'user@example.com',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatarWithInitials(
              initials: _getInitials(currentUser?.name ?? 'K'),
              radius: 28,
              backgroundColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              textColor: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.grey[800]!, Colors.grey[900]!]
                    : [AppColors.primaryColor, const Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Ana Sayfa
          _buildDrawerTile(
            context,
            title: 'Ana Sayfa',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            isSelected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),

          // Mesajlar
          _buildDrawerTile(
            context,
            title: 'Mesajlar',
            icon: Icons.mark_email_unread_outlined,
            selectedIcon: Icons.mark_email_unread,
            isSelected: _selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              context.go('/messages');
            },
          ),

          // Görevler
          _buildDrawerTile(
            context,
            title: 'Görevler',
            icon: Icons.task_outlined,
            selectedIcon: Icons.task,
            isSelected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              context.go('/tasks');
            },
          ),

          // Takvim
          _buildDrawerTile(
            context,
            title: 'Takvim',
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
            isSelected: _selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              context.go('/calendar');
            },
          ),

          // E-posta
          _buildDrawerTile(
            context,
            title: 'E-posta',
            icon: Icons.email_outlined,
            selectedIcon: Icons.email,
            isSelected: _selectedIndex == 5,
            onTap: () {
              Navigator.pop(context);
              context.go('/email');
            },
          ),

          // Analytics
          _buildDrawerTile(
            context,
            title: 'Analytics',
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            isSelected: _selectedIndex == 6,
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),

          // AI Asistan
          _buildDrawerTile(
            context,
            title: 'AI Asistan',
            icon: Icons.smart_toy_outlined,
            selectedIcon: Icons.smart_toy,
            isSelected: _selectedIndex == 7,
            onTap: () {
              Navigator.pop(context);
              context.go('/ai-assistant');
            },
          ),

          const Divider(height: 32),

          // Ayarlar
          _buildDrawerTile(
            context,
            title: 'Ayarlar',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            isSelected: _selectedIndex == 8,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 8;
              });
              context.go('/settings');
            },
          ),

          // Tema Değiştir
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.amber[300] : Colors.orange[600],
            ),
            title: Text(
              isDarkMode ? 'Açık Mod' : 'Koyu Mod',
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          // Çıkış Yap
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showSignOutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? (isDarkMode ? Colors.white : AppColors.primaryColor)
            : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? (isDarkMode ? Colors.white : AppColors.primaryColor)
              : (isDarkMode ? Colors.grey[300] : Colors.black87),
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor:
          isDarkMode ? Colors.grey[800]?.withValues(alpha: 0.3) : AppColors.primaryColor.withValues(alpha: 0.1),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userNotifierProvider.notifier).signOut();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return 'K';
  }

  void _handleNavigation(int index) async {
    // Navigate to the respective page if not home
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Birleşik Mesajlar
        context.go('/messages');
        break;
      case 2:
        context.go('/tasks');
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
}
