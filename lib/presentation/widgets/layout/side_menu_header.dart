import 'package:flutter/material.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(
            'AI Asistan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Kişisel Yönetim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

