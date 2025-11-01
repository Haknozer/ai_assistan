import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../models/user.dart' as app_user;
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../widgets/layout/bottom_navigation.dart';
import '../../widgets/layout/mobile_app_bar.dart';
import 'dashboard_page.dart';
import '../tasks/tasks_screen.dart';
import '../calendar/calendar_screen.dart';
import '../email/email_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    Container(), // Birleşik Mesajlar - TODO: Create page
    const TasksScreen(),
    const CalendarScreen(),
    const EmailScreen(),
    const AnalyticsScreen(),
    Container(), // AI Asistan - TODO: Create page
    const SettingsScreen(),
    Container(), // Komut Paleti - TODO: Create page
    Container(), // Karanlık Mod - TODO: Create page
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const _LoadingWidget();
    }

    return ResponsiveUtils.isDesktop(context)
        ? _DesktopLayout(
            currentUser: currentUser,
            selectedIndex: _selectedIndex,
            pages: _pages,
            onMenuTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _handleNavigation(index);
            },
            onProfileTap: _handleProfileTap,
          )
        : _MobileLayout(
            currentUser: currentUser,
            selectedIndex: _selectedIndex,
            pages: _pages,
            onMenuTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _handleNavigation(index);
            },
            onProfileTap: _handleProfileTap,
            onNotificationsPressed: _handleNotificationsPressed,
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

  void _handleNavigation(int index) {
    // Navigate to the respective page if not home
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Birleşik Mesajlar - TODO: Create route
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Birleşik Mesajlar geliştiriliyor...')),
        );
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
        // AI Asistan - TODO: Create route
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Asistan geliştiriliyor...')),
        );
        break;
      case 7:
        // Komut Paleti - TODO: Create route
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
      case 8:
        // Karanlık Mod - TODO: Toggle dark mode
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karanlık Mod geliştiriliyor...')),
        );
        break;
    }
  }
}

// Loading Widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Desktop Layout Widget
class _DesktopLayout extends StatelessWidget {
  final app_user.User currentUser;
  final int selectedIndex;
  final List<Widget> pages;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;

  const _DesktopLayout({
    required this.currentUser,
    required this.selectedIndex,
    required this.pages,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Row(
        children: [
          // Fixed Side Menu (Desktop)
          SizedBox(
            width: 280,
            child: SideMenu(
              userName: currentUser.name,
              userEmail: currentUser.email,
              selectedIndex: selectedIndex,
              onMenuTap: onMenuTap,
              onProfileTap: onProfileTap,
            ),
          ),
          // Main Content Area
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

// Mobile Layout Widget
class _MobileLayout extends StatelessWidget {
  final app_user.User currentUser;
  final int selectedIndex;
  final List<Widget> pages;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsPressed;

  const _MobileLayout({
    required this.currentUser,
    required this.selectedIndex,
    required this.pages,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onNotificationsPressed,
  });

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Birleşik Mesajlar';
      case 2:
        return 'Görevler';
      case 3:
        return 'Takvim';
      case 4:
        return 'E-Posta';
      case 5:
        return 'Analitik';
      case 6:
        return 'AI Asistan';
      case 7:
        return 'Komut Paleti';
      case 8:
        return 'Karanlık Mod';
      default:
        return 'AI Asistan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      appBar: MobileAppBar(
        title: _getAppBarTitle(selectedIndex),
        onMenuPressed: () {
          Scaffold.of(context).openDrawer();
        },
        onNotificationsPressed: onNotificationsPressed,
      ),
      drawer: SizedBox(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: selectedIndex,
          onMenuTap: (index) {
            onMenuTap(index);
            Navigator.pop(context); // Close drawer
          },
          onProfileTap: () {
            Navigator.pop(context); // Close drawer
            onProfileTap();
          },
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: selectedIndex,
        onTap: onMenuTap,
      ),
    );
  }
}
