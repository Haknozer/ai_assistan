import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthToggle extends StatelessWidget {
  final bool isLogin;
  final VoidCallback? onToggleMode;

  const AuthToggle({
    super.key,
    required this.isLogin,
    this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isLogin) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Şifremi Unuttum
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Şifremi Unuttum?',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationThickness: 1,
                decorationColor: AppColors.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Kayıt Ol
          TextButton(
            onPressed: onToggleMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Hesabınız yok mu? Kaydol',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: onToggleMode,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Zaten hesabınız var mı? Giriş Yap',
          style: TextStyle(
            color: AppColors.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }
  }
}
