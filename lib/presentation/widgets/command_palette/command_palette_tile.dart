import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'command_palette_action.dart';
import 'command_palette_shortcut_chip.dart';

class CommandPaletteTile extends StatelessWidget {
  final CommandPaletteAction action;
  final VoidCallback onTap;

  const CommandPaletteTile({
    super.key,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(action.icon, color: isDark ? Colors.white : AppColors.primaryColor),
      title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(action.description),
      trailing: CommandPaletteShortcutChip(label: action.shortcutLabel),
      onTap: onTap,
    );
  }
}

