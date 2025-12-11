import 'package:flutter/material.dart';

class CommandPaletteAction {
  final String title;
  final String description;
  final IconData icon;
  final String shortcutLabel;
  final String? route;
  final VoidCallback? onTap;

  const CommandPaletteAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.shortcutLabel,
    this.route,
    this.onTap,
  });
}

