import 'package:flutter/material.dart';

class CircleAvatarWithInitials extends StatelessWidget {
  final String initials;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final FontWeight? fontWeight;
  final double? fontSize;

  const CircleAvatarWithInitials({
    super.key,
    required this.initials,
    required this.radius,
    required this.backgroundColor,
    required this.textColor,
    this.fontWeight,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontSize: fontSize ?? (radius * 0.8),
        ),
      ),
    );
  }
}