import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'command_palette_action.dart';
import 'command_palette_actions.dart';
import 'command_palette_empty_result.dart';
import 'command_palette_tile.dart';

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
    _actions = getCommandPaletteActions();
    _isCommandPaletteOpen = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    ? const CommandPaletteEmptyResult()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final action = filtered[index];
                          return CommandPaletteTile(
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
