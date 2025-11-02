import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/home/desktop_layout.dart';
import '../../widgets/home/mobile_layout.dart';
import '../../widgets/home/loading_widget.dart';
import 'dashboard_page.dart';
import '../tasks/tasks_screen.dart';
import '../calendar/calendar_screen.dart';
import '../email/email_screen.dart';
import '../analytics/analytics_screen.dart';
import '../messages/unified_messages_screen.dart';

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
    Container(), // AI Asistan - TODO: Create page
    Container(), // Komut Paleti - TODO: Create page
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
              setState(() {
                _selectedIndex = index;
              });
              _handleNavigation(index);
            },
            onProfileTap: _handleProfileTap,
          )
        : MobileLayout(
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

  void _handleNavigation(int index) async {
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
    }
  }
}
