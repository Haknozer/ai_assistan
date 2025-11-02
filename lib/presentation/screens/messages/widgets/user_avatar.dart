import 'package:flutter/material.dart';

/// Kullanıcı avatarı widget'ı - Baş harfleri gösteren yuvarlak avatar
class UserAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final double fontSize;

  const UserAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 48,
    this.fontSize = 16,
  });

  String _getInitials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

