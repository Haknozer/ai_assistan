import 'package:flutter/material.dart';

class SideMenuItem {
  final IconData icon;
  final String label;
  final int index;

  const SideMenuItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

List<SideMenuItem> getSideMenuItems() {
  return const [
    SideMenuItem(icon: Icons.dashboard_outlined, label: 'Ana Sayfa', index: 0),
    SideMenuItem(icon: Icons.mark_email_unread_outlined, label: 'Birleşik Mesajlar', index: 1),
    SideMenuItem(icon: Icons.task_outlined, label: 'Görevler', index: 2),
    SideMenuItem(icon: Icons.calendar_today_outlined, label: 'Takvim', index: 3),
    SideMenuItem(icon: Icons.email_outlined, label: 'E-Posta', index: 4),
    SideMenuItem(icon: Icons.analytics_outlined, label: 'Analitik', index: 5),
    SideMenuItem(icon: Icons.smart_toy_outlined, label: 'AI Asistan', index: 6),
    SideMenuItem(icon: Icons.search, label: 'Komut Paleti', index: 7),
    SideMenuItem(icon: Icons.settings_outlined, label: 'Ayarlar', index: 8),
  ];
}

