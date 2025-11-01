import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/circle_avatar_with_initials.dart';
import '../../../../providers/theme_provider.dart';

class SideMenu extends ConsumerWidget {
  final String userName;
  final String userEmail;
  final int selectedIndex;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;

  const SideMenu({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.selectedIndex,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          _buildHeader(),

          // User Profile Card
          _buildUserProfileCard(),

          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: _buildMenuItems(ref),
          ),

          // Bottom Section
          _buildBottomSection(ref),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12),

          // App Title
          Text(
            'AI Asistan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          SizedBox(height: 2),

          // Subtitle
          Text(
            'Kişisel Yönetim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatarWithInitials(
                initials: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                radius: 24,
                backgroundColor: Colors.white,
                textColor: AppColors.primaryColor,
              ),
            ),

            const SizedBox(width: 10),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(WidgetRef ref) {
    final menuItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Ana Sayfa', 'index': 0},
      {'icon': Icons.mark_email_unread_outlined, 'label': 'Birleşik Mesajlar', 'index': 1},
      {'icon': Icons.task_outlined, 'label': 'Görevler', 'index': 2},
      {'icon': Icons.calendar_today_outlined, 'label': 'Takvim', 'index': 3},
      {'icon': Icons.email_outlined, 'label': 'E-Posta', 'index': 4},
      {'icon': Icons.analytics_outlined, 'label': 'Analitik', 'index': 5},
      {'icon': Icons.smart_toy_outlined, 'label': 'AI Asistan', 'index': 6},
      {'icon': Icons.search, 'label': 'Komut Paleti', 'index': 7},
    ];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: menuItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            final itemIndex = item['index'] as int;
            final isSelected = selectedIndex == itemIndex;

            return GestureDetector(
              onTap: () => onMenuTap(itemIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSection(WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),

          const SizedBox(height: 16),

          // Karanlık/Aydınlık Mod Butonu
          GestureDetector(
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    themeState.isDarkMode ? 'Açık Mod' : 'Karanlık Mod',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout Button
          GestureDetector(
            onTap: () {
              // TODO: Implement logout
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
