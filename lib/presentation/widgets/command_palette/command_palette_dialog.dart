import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

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

bool _isCommandPaletteOpen = false;

Future<void> showCommandPaletteDialog(
  BuildContext context, {
  GoRouter? router,
  BuildContext? navigatorContext,
}) async {
  final ctx = navigatorContext ?? context;

  if (_isCommandPaletteOpen) {
    Navigator.of(ctx, rootNavigator: true).pop();
    return;
  }

  return showDialog(
    context: ctx,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) => _CommandPaletteDialog(router: router),
  ).whenComplete(() {
    _isCommandPaletteOpen = false;
  });
}

class _CommandPaletteDialog extends StatefulWidget {
  final GoRouter? router;

  const _CommandPaletteDialog({this.router});

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  late final List<CommandPaletteAction> _actions;

  @override
  void initState() {
    super.initState();
    _actions = _buildActions();
    _isCommandPaletteOpen = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CommandPaletteAction> _buildActions() {
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
        title: 'Ayarlar',
        description: 'Genel ve entegrasyon ayarları',
        icon: Icons.settings_outlined,
        shortcutLabel: 'Ctrl/Cmd + S',
        route: '/settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.toLowerCase();
    final filtered = _actions.where((a) {
      return a.title.toLowerCase().contains(query) || a.description.toLowerCase().contains(query);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Komut ara veya kısayolu gör',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyResult()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final action = filtered[index];
                          return _CommandTile(
                            action: action,
                            onTap: () {
                              Navigator.of(context).pop();
                              if (action.onTap != null) {
                                action.onTap!();
                                return;
                              }
                              if (action.route != null && widget.router != null) {
                                widget.router!.go(action.route!);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final CommandPaletteAction action;
  final VoidCallback onTap;

  const _CommandTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(action.icon, color: isDark ? Colors.white : AppColors.primaryColor),
      title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(action.description),
      trailing: _ShortcutChip(label: action.shortcutLabel),
      onTap: onTap,
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;

  const _ShortcutChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          const Text('Sonuç bulunamadı'),
          const SizedBox(height: 4),
          Text(
            'Arama terimini değiştir veya kısayollara göz at',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

