import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/circle_avatar_with_initials.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 1.0),
            AppColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hoş Geldin Metni
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldin,',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.secondaryTextColor,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryTextColor,
                              fontSize: 12,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Profil ve Notification
                Row(
                  children: [
                    // Notification Button
                    Stack(
                      children: [
                        IconButton(
                          onPressed: onNotificationTap,
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primaryTextColor,
                            size: 28,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Profile Avatar
                    GestureDetector(
                      onTap: onProfileTap,
                      child: CircleAvatarWithInitials(
                        initials: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        radius: 24,
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Row - Mobile için vertical, Desktop için horizontal
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop/Tablet view - Horizontal
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(context, 'Bugünkü Görevler', '5', Icons.task_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Tamamlanan', '12', Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(context, 'Etkinlikler', '3', Icons.event_outlined)),
                    ],
                  );
                } else {
                  // Mobile view - Vertical
                  return Column(
                    children: [
                      _buildStatCard(context, 'Bugünkü Görevler', '5', Icons.task_outlined),
                      const SizedBox(height: 8),
                      _buildStatCard(context, 'Tamamlanan', '12', Icons.check_circle_outline),
                      const SizedBox(height: 8),
                      _buildStatCard(context, 'Etkinlikler', '3', Icons.event_outlined),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryTextColor,
                        fontSize: 11,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
