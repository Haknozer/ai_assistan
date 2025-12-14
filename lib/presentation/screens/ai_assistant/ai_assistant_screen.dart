import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_config.dart';
import '../../../utils/responsive_utils.dart';
import '../../../providers/user_provider.dart';
import '../../../features/ai/ai_feature.dart';
import '../../../providers/location_provider.dart';
import '../../widgets/command_palette/command_palette_dialog.dart';
import '../../../core/router/app_router.dart';
import '../../../services/chat_history_service.dart';
import '../../widgets/voice/voice_command_sheet.dart';
import '../../../services/voice/voice_command_helper.dart';
import '../../widgets/ai_assistant/ai_assistant_desktop_layout.dart';
import '../../widgets/ai_assistant/ai_assistant_mobile_layout.dart';

/// AI Asistan Ekranı - Yapay zeka destekli chat
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final int _selectedMenuIndex = 6; // AI Assistant indeksi
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Position? _currentPosition;
  String? _supabaseUserId;
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadSupabaseUserId();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(currentUser, padding, isDesktop),
    );
  }

  Widget _buildResponsiveLayout(dynamic currentUser, EdgeInsets padding, bool isDesktop) {
    if (isDesktop) {
      return AiAssistantDesktopLayout(
        currentUser: currentUser,
        padding: padding,
        selectedMenuIndex: _selectedMenuIndex,
        onMenuTap: _handleMenuTap,
        onProfileTap: _handleProfileTap,
        onVoiceTap: _openVoiceSheet,
        messages: _messages,
        onSuggestionTap: _handleSuggestionTap,
        scrollController: _scrollController,
        messageController: _messageController,
        onSendMessage: _sendMessage,
        isTyping: _isTyping,
      );
    }

    return AiAssistantMobileLayout(
      currentUser: currentUser,
      padding: padding,
      selectedMenuIndex: _selectedMenuIndex,
      onMenuTap: _handleMenuTap,
      onProfileTap: _handleProfileTap,
      onVoiceTap: _openVoiceSheet,
      messages: _messages,
      onSuggestionTap: _handleSuggestionTap,
      scrollController: _scrollController,
      messageController: _messageController,
      onSendMessage: _sendMessage,
      isTyping: _isTyping,
    );
  }

  void _handleSuggestionTap(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;
    await _sendThroughChatFlow(text, clearController: true);
  }

  Future<String?> _sendVoiceMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return null;
    return _sendThroughChatFlow(text, clearController: false);
  }

  Future<String?> _sendThroughChatFlow(String text, {bool clearController = false}) async {
    final userId = ref.read(supabaseAuthServiceProvider).getCurrentUser()?.id ?? _supabaseUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.')),
        );
      }
      setState(() {
        _isTyping = false;
      });
      return null;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      if (clearController) {
        _messageController.clear();
      }
      _isTyping = true;
    });

    return _sendToChatbot(text, userId);
  }

  Future<String?> _sendToChatbot(String text, String userId) async {
    // Konum henüz alınamadıysa gönderim öncesi bir kez daha dene
    _currentPosition ??= await ref.read(locationServiceProvider).getLastKnownLocation();

    try {
      if (!mounted) return null;
      final connections = await VoiceCommandHelper.resolveEmailConnections(userId: null);
      final assistantText = await VoiceCommandHelper.processVoiceCommand(
        context: context,
        text: text,
        userId: userId,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        gmailConnected: connections.gmail,
        outlookConnected: connections.outlook,
      );

      if (!mounted) return null;

      setState(() {
        _isTyping = false;
        if (assistantText != null && assistantText.isNotEmpty) {
          _messages.add(ChatMessage(
            text: assistantText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
      });
      _scrollToBottom();
      return assistantText;
    } catch (e) {
      if (!mounted) return null;
      setState(() {
        _isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
      );
      return null;
    }
  }

  Future<void> _initLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _loadSupabaseUserId() async {
    final supabaseUser = ref.read(supabaseAuthServiceProvider).getCurrentUser();
    if (!mounted) return;
    setState(() {
      _supabaseUserId = supabaseUser?.id;
    });
    final userId = _supabaseUserId;
    if (userId != null) {
      // Cache varsa anında göster
      final cached = _chatHistoryService.getCachedMessages(userId);
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _messages
            ..clear()
            ..addAll(cached);
        });
        _scrollToBottom();
      }
      // Cache yüklü değilse tek sefer istek at
      if (!_chatHistoryService.isLoaded(userId)) {
        await _loadChatHistory(userId);
      }
    }
  }

  Future<void> _loadChatHistory(String userId) async {
    try {
      final history = await _chatHistoryService.fetchHistory(userId: userId, limit: 200);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş yüklenemedi: $e')),
      );
    }
  }

  void _handleMenuTap(int index) {
    if (index == 6) return; // Zaten AI Assistant'tayız

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/messages');
        break;
      case 2:
        context.go('/tasks');
        break;
      case 3:
        context.go('/calendar');
        break;
      case 4:
        context.go('/email');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 7:
        showCommandPaletteDialog(
          context,
          router: GoRouter.of(context),
          navigatorContext: rootNavigatorKey.currentContext,
        );
        break;
      case 8:
        context.go('/settings');
        break;
      case 9:
        _openVoiceSheet();
        break;
    }
  }

  void _handleProfileTap() {
    context.go('/settings');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openVoiceSheet() async {
    const servicePath = AppConfig.googleApplicationCredentials;
    if (servicePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GOOGLE_APPLICATION_CREDENTIALS tanımlı değil')),
        );
      }
      return;
    }

    // Supabase ID zorunlu; yoksa gönderme
    final userId = ref.read(supabaseAuthServiceProvider).getCurrentUser()?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı oturumu bulunamadı')),
        );
      }
      return;
    }

    // Konum yoksa açmadan önce bir kez daha dene
    if (_currentPosition == null) {
      final freshPos = await ref.read(locationServiceProvider).getCurrentLocation();
      if (freshPos != null) {
        setState(() {
          _currentPosition = freshPos;
        });
      }
    }

    if (!mounted) return;

    await showVoiceCommandSheet(
      context,
      serviceAccountPath: servicePath,
      languageCode: AppConfig.gcpSttLanguage,
      voiceName: AppConfig.gcpTtsVoice,
      audioEncoding: AppConfig.gcpTtsEncoding,
      userId: userId,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      onSendVoice: _sendVoiceMessage,
    );
  }
}
