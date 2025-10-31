import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 50,
            color: AppColors.primaryColor,
          ),
        ),

        const SizedBox(height: 24),

        // Uygulama Adı
        const Text(
          'AI Asistan',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTextColor,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Alt Başlık
        const Text(
          'Kişisel Yönetim Platformu',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}