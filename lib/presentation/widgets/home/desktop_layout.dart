import 'package:flutter/material.dart';
import '../../../models/user.dart' as app_user;
import '../layout/side_menu.dart';

class DesktopLayout extends StatelessWidget {
  final app_user.User currentUser;
  final int selectedIndex;
  final List<Widget> pages;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;

  const DesktopLayout({
    super.key,
    required this.currentUser,
    required this.selectedIndex,
    required this.pages,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              index: selectedIndex >= 0 && selectedIndex < pages.length ? selectedIndex : 0,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

