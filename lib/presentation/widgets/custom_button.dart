import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final bool isLoading;
  final Widget? child;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.isLoading = false,
    this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isIconStyle = icon != null;
    final buttonBgColor = backgroundColor ?? AppColors.buttonBackground;

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: Container(
        decoration: BoxDecoration(
          color: buttonBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            highlightColor: AppColors.primaryColor.withValues(alpha: 0.05),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          textColor ?? AppColors.primaryTextColor,
                        ),
                      ),
                    )
                  : child ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isIconStyle) ...[
                            Icon(
                              icon,
                              size: 18,
                              color: textColor ?? AppColors.primaryTextColor,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor ?? AppColors.primaryTextColor,
                            ),
                          ),
                          if (!isIconStyle) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: textColor ?? AppColors.primaryTextColor,
                            ),
                          ],
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}