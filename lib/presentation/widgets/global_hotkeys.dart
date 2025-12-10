import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/rendering.dart';

import '../../core/router/app_router.dart';
import 'command_palette/command_palette_dialog.dart';

/// Uygulama genelinde klavye kısayolları (desktop/web).
/// Örnek: h -> /home, m -> /messages, t -> /tasks, c -> /calendar,
/// e -> /email, a -> /analytics, s -> /settings, k -> /command-palette.
class GlobalHotkeys extends ConsumerWidget {
  final Widget child;

  const GlobalHotkeys({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);
    final buildContext = context;

    final shortcuts = <LogicalKeySet, Intent>{
      // Ctrl/Cmd + key kombinasyonları; düz harfleri kaldırdık ki yazı alanlarını etkilemesin
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH):
          const _NavigateIntent('/home'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyH):
          const _NavigateIntent('/home'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM):
          const _NavigateIntent('/messages'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyM):
          const _NavigateIntent('/messages'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT):
          const _NavigateIntent('/tasks'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyT):
          const _NavigateIntent('/tasks'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
          const _NavigateIntent('/calendar'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
          const _NavigateIntent('/calendar'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE):
          const _NavigateIntent('/email'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE):
          const _NavigateIntent('/email'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
          const _NavigateIntent('/analytics'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
          const _NavigateIntent('/analytics'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          const _NavigateIntent('/settings'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
          const _NavigateIntent('/settings'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
          const _NavigateIntent('/ai-assistant'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI):
          const _NavigateIntent('/ai-assistant'),

      // Komut paleti için Ctrl/Cmd+K
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
          const _NavigateIntent('__palette__'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
          const _NavigateIntent('__palette__'),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              // Sadece text girişi üzerinde değilsek çalıştır
              if (_isTextInputFocused()) return null;

              // Focus engelini kaldırmak için unfocus
              FocusManager.instance.primaryFocus?.unfocus();
              if (intent.route == '__palette__') {
                final navContext = router.routerDelegate.navigatorKey.currentContext;
                showCommandPaletteDialog(
                  buildContext,
                  router: router,
                  navigatorContext: navContext,
                );
                return null;
              }
              router.go(intent.route);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _NavigateIntent extends Intent {
  final String route;
  const _NavigateIntent(this.route);
}

bool _isTextInputFocused() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;
  // Eğer fokus EditableText ise (metin alanı)
  if (focus.context?.widget is EditableText) return true;
  if (focus.context?.findAncestorWidgetOfExactType<EditableText>() != null) return true;
  if (focus.context?.findAncestorRenderObjectOfType<RenderEditable>() != null) return true;

  // Fokus scope'un aktif çocuğunu da kontrol et
  if (focus is FocusScopeNode) {
    final child = focus.focusedChild;
    if (child?.context?.widget is EditableText) return true;
    if (child?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return true;
    if (child?.context?.findAncestorRenderObjectOfType<RenderEditable>() != null) return true;
  }

  // Debug label kontrolü (bazı platformlarda)
  final label = focus.debugLabel?.toLowerCase() ?? '';
  if (label.contains('editabletext')) return true;

  return false;
}

