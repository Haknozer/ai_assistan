import 'package:flutter/material.dart';

import 'command_palette_action.dart';

List<CommandPaletteAction> getCommandPaletteActions() {
  return const [
    CommandPaletteAction(
      title: 'Ana Sayfa',
      description: 'Genel görünüm ve panolar',
      icon: Icons.dashboard_outlined,
      shortcutLabel: 'Ctrl/Cmd + H',
      route: '/home',
    ),
    CommandPaletteAction(
      title: 'Birleşik Mesajlar',
      description: 'Mesaj ve sohbet kutusu',
      icon: Icons.mark_email_unread_outlined,
      shortcutLabel: 'Ctrl/Cmd + M',
      route: '/messages',
    ),
    CommandPaletteAction(
      title: 'Görevler',
      description: 'Görev listesi ve durumlar',
      icon: Icons.task_outlined,
      shortcutLabel: 'Ctrl/Cmd + T',
      route: '/tasks',
    ),
    CommandPaletteAction(
      title: 'Takvim',
      description: 'Etkinlik ve toplantılar',
      icon: Icons.calendar_today_outlined,
      shortcutLabel: 'Ctrl/Cmd + C',
      route: '/calendar',
    ),
    CommandPaletteAction(
      title: 'E-Posta',
      description: 'Kutular ve şablonlar',
      icon: Icons.email_outlined,
      shortcutLabel: 'Ctrl/Cmd + E',
      route: '/email',
    ),
    CommandPaletteAction(
      title: 'Analitik',
      description: 'Performans ve raporlar',
      icon: Icons.analytics_outlined,
      shortcutLabel: 'Ctrl/Cmd + A',
      route: '/analytics',
    ),
    CommandPaletteAction(
      title: 'AI Asistan',
      description: 'Prompt ve öneriler',
      icon: Icons.smart_toy_outlined,
      shortcutLabel: 'Ctrl/Cmd + I',
      route: '/ai-assistant',
    ),
    CommandPaletteAction(
      title: 'Sesli Asistan (PTT)',
      description: 'Bas-konuş ile n8n + TTS',
      icon: Icons.mic_outlined,
      shortcutLabel: 'Ctrl/Cmd + Shift + V',
      route: '/ai-assistant',
    ),
    CommandPaletteAction(
      title: 'Ayarlar',
      description: 'Genel ve entegrasyon ayarları',
      icon: Icons.settings_outlined,
      shortcutLabel: 'Ctrl/Cmd + S',
      route: '/settings',
    ),
  ];
}

