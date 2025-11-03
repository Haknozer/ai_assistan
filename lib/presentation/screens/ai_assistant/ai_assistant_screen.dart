import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import 'models/chat_message.dart';
import 'data/ai_responses.dart';
import '../../widgets/ai_assistant/ai_page_header.dart';
import '../../widgets/ai_assistant/chat_area.dart';
import '../../widgets/ai_assistant/chat_message_input.dart';

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
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
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
      return _buildDesktopLayout(currentUser, padding);
    } else {
      return _buildMobileLayout(currentUser, padding);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(dynamic currentUser, EdgeInsets padding) {
    return Row(
      children: [
        // Sol Menü
        SizedBox(
          width: 280,
          child: SideMenu(
            userName: currentUser.name,
            userEmail: currentUser.email,
            selectedIndex: _selectedMenuIndex,
            onMenuTap: _handleMenuTap,
            onProfileTap: _handleProfileTap,
          ),
        ),
        // Ana İçerik Alanı
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sayfa Başlığı
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: AIPageHeader(),
                  ),

                  // Chat İçeriği
                  Expanded(
                    child: ChatArea(
                      messages: _messages,
                      onSuggestionTap: _handleSuggestionTap,
                    ),
                  ),

                  // Mesaj Girişi
                  ChatMessageInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                    isTyping: _isTyping,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout - AppBar + Drawer + içerik
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Asistan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mobil Hoş Geldiniz Mesajı
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${currentUser.name.split(' ').first}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Size nasıl yardımcı olabilirim?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),

            // Chat İçeriği
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChatArea(
                  messages: _messages,
                  onSuggestionTap: _handleSuggestionTap,
                ),
              ),
            ),

            // Mesaj Girişi
            ChatMessageInput(
              controller: _messageController,
              onSend: _sendMessage,
              isTyping: _isTyping,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: _selectedMenuIndex,
          onMenuTap: (index) {
            Navigator.pop(context);
            _handleMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context);
            _handleProfileTap();
          },
        ),
      ),
    );
  }

  void _handleSuggestionTap(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    // Simulate AI response
    _simulateAIResponse(text);
  }

  void _simulateAIResponse(String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: AIResponses.generateResponse(userMessage),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
    }
  }

  void _handleProfileTap() {
    context.go('/settings');
  }
}
