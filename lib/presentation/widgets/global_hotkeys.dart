import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/logger.dart';
import '../../providers/user_provider.dart' as user_providers;
import '../../providers/location_provider.dart';
import '../../services/voice/wake_word_service.dart';
import 'voice/voice_command_sheet.dart';
import '../../services/voice/voice_command_helper.dart';
import 'command_palette/command_palette_dialog.dart';

/// Uygulama genelinde klavye kısayolları (desktop/web) ve "Jarvis" wake word desteği.
/// Örnek: h -> /home, m -> /messages, t -> /tasks, c -> /calendar,
/// e -> /email, a -> /analytics, s -> /settings, k -> /command-palette.
/// "Jarvis" dediğinizde sesli asistan otomatik açılır.
class GlobalHotkeys extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalHotkeys({super.key, required this.child});

  @override
  ConsumerState<GlobalHotkeys> createState() => _GlobalHotkeysState();
}

class _GlobalHotkeysState extends ConsumerState<GlobalHotkeys> with WidgetsBindingObserver {
  final WakeWordService _wakeWordService = WakeWordService();
  bool _wakeWordInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Widget mount edildikten sonra wake word'ü başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWakeWord();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wakeWordService.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gidince durdur, öne gelince başlat
    if (state == AppLifecycleState.resumed) {
      _wakeWordService.startListening();
    } else if (state == AppLifecycleState.paused) {
      _wakeWordService.stopListening();
    }
  }

  Future<void> _initWakeWord() async {
    if (_wakeWordInitialized) return;

    try {
      await _wakeWordService.init(
        onWakeWordDetected: () {
          AppLogger.info('Jarvis detected! Opening voice sheet...', 'WAKE_WORD');
          _openVoiceSheet();
        },
      );
      await _wakeWordService.startListening();
      _wakeWordInitialized = true;
      AppLogger.info('Wake word listening active - say "Jarvis"!', 'WAKE_WORD');
    } catch (e) {
      AppLogger.error('Failed to initialize wake word', error: e, tag: 'WAKE_WORD');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jarvis başlatılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openVoiceSheet() async {
    const servicePath = AppConfig.googleApplicationCredentials;
    if (servicePath.isEmpty) return;

    final supa = ref.read(user_providers.supabaseAuthServiceProvider);
    final userId = supa.getCurrentUser()?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı oturumu bulunamadı')),
        );
      }
      return;
    }

    // Konum ekle
    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getLastKnownLocation() ?? await locationService.getCurrentLocation();

    if (!mounted) return;

    final router = ref.read(routerProvider);
    final navContext = router.routerDelegate.navigatorKey.currentContext ?? context;
    if (!navContext.mounted) return;

    // Wake word dinlemeyi durdur (voice sheet açıkken)
    await _wakeWordService.stopListening();

    // Re-check mounted after async gap before using context
    if (!mounted || !navContext.mounted) return;

    await showVoiceCommandSheet(
      navContext,
      serviceAccountPath: servicePath,
      languageCode: AppConfig.gcpSttLanguage,
      voiceName: AppConfig.gcpTtsVoice,
      audioEncoding: AppConfig.gcpTtsEncoding,
      userId: userId,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      onSendVoice: (text) async {
        if (!navContext.mounted) return null;
        final connections = await VoiceCommandHelper.resolveEmailConnections(userId: null);
        if (!navContext.mounted) return null;
        return await VoiceCommandHelper.processVoiceCommand(
          context: navContext,
          text: text,
          userId: userId,
          latitude: pos?.latitude,
          longitude: pos?.longitude,
          gmailConnected: connections.gmail,
          outlookConnected: connections.outlook,
        );
      },
    );

    // Voice sheet kapandıktan sonra wake word dinlemeyi tekrar başlat
    if (mounted) {
      await _wakeWordService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.read(routerProvider);
    final buildContext = context;

    final shortcuts = <LogicalKeySet, Intent>{
      // Ctrl/Cmd + key kombinasyonları; düz harfleri kaldırdık ki yazı alanlarını etkilemesin
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): const _NavigateIntent('/home'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyH): const _NavigateIntent('/home'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM): const _NavigateIntent('/messages'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyM): const _NavigateIntent('/messages'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): const _NavigateIntent('/tasks'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyT): const _NavigateIntent('/tasks'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): const _NavigateIntent('/calendar'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC): const _NavigateIntent('/calendar'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE): const _NavigateIntent('/email'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE): const _NavigateIntent('/email'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): const _NavigateIntent('/analytics'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA): const _NavigateIntent('/analytics'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const _NavigateIntent('/settings'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): const _NavigateIntent('/settings'),

      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): const _NavigateIntent('/ai-assistant'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI): const _NavigateIntent('/ai-assistant'),

      // Komut paleti için Ctrl/Cmd+K
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _NavigateIntent('__palette__'),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _NavigateIntent('__palette__'),

      // Sesli asistan (Ctrl/Cmd + V)
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV): const _VoiceSheetIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV): const _VoiceSheetIntent(),
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
          _VoiceSheetIntent: CallbackAction<_VoiceSheetIntent>(
            onInvoke: (intent) async {
              await _openVoiceSheet();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }
}

class _NavigateIntent extends Intent {
  final String route;
  const _NavigateIntent(this.route);
}

class _VoiceSheetIntent extends Intent {
  const _VoiceSheetIntent();
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
