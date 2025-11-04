import 'package:flutter/material.dart';
import '../../../models/user.dart' as app_user;
import '../layout/bottom_navigation.dart';
import '../layout/mobile_app_bar.dart';

class MobileLayout extends StatelessWidget {
  final app_user.User currentUser;
  final int selectedIndex;
  final List<Widget> pages;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsPressed;

  const MobileLayout({
    super.key,
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
      default:
        return 'AI Asistan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      bottomNavigationBar: BottomNavigation(
        selectedIndex: selectedIndex,
        onTap: onMenuTap,
      ),
    );
  }
}
