import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../circle_avatar_with_initials.dart';

class SideMenuProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onProfileTap;

  const SideMenuProfileCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
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
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatarWithInitials(
                initials: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                radius: 20,
                backgroundColor: Colors.white,
                textColor: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
}

