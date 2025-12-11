import 'package:flutter/material.dart';

import '../../../features/ai/ai_feature.dart';
import '../layout/side_menu.dart';
import 'ai_page_header.dart';
import 'chat_area.dart';
import 'chat_message_input.dart';

class AiAssistantDesktopLayout extends StatelessWidget {
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

  const AiAssistantDesktopLayout({
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
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: SideMenu(
            userName: currentUser.name,
            userEmail: currentUser.email,
            selectedIndex: selectedMenuIndex,
            onMenuTap: onMenuTap,
            onProfileTap: onProfileTap,
            onVoiceTap: onVoiceTap,
          ),
        ),
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const Expanded(child: AIPageHeader()),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: onVoiceTap,
                          icon: const Icon(Icons.mic_outlined),
                          label: const Text('Sesli Asistan'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ChatArea(
                      messages: messages,
                      onSuggestionTap: onSuggestionTap,
                      scrollController: scrollController,
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
          ),
        ),
      ],
    );
  }
}

