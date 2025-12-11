import 'package:flutter/material.dart';

import '../../../features/ai/ai_feature.dart';
import '../layout/side_menu.dart';
import 'chat_area.dart';
import 'chat_message_input.dart';

class AiAssistantMobileLayout extends StatelessWidget {
  final dynamic currentUser;
  final EdgeInsets padding;
  final int selectedMenuIndex;
  final void Function(int) onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback onVoiceTap;
  final List<ChatMessage> messages;
  final void Function(String) onSuggestionTap;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final Future<void> Function() onSendMessage;
  final bool isTyping;

  const AiAssistantMobileLayout({
    super.key,
    required this.currentUser,
    required this.padding,
    required this.selectedMenuIndex,
    required this.onMenuTap,
    required this.onProfileTap,
    required this.onVoiceTap,
    required this.messages,
    required this.onSuggestionTap,
    required this.scrollController,
    required this.messageController,
    required this.onSendMessage,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            onPressed: onVoiceTap,
            icon: const Icon(Icons.mic_outlined),
            tooltip: 'Sesli Asistan (Ctrl/Cmd+Shift+V)',
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChatArea(
                  messages: messages,
                  onSuggestionTap: onSuggestionTap,
                  scrollController: scrollController,
                ),
              ),
            ),
            ChatMessageInput(
              controller: messageController,
              onSend: onSendMessage,
              isTyping: isTyping,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: selectedMenuIndex,
          onMenuTap: (index) {
            Navigator.pop(context);
            onMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context);
            onProfileTap();
          },
          onVoiceTap: () {
            Navigator.pop(context);
            onVoiceTap();
          },
        ),
      ),
    );
  }
}

