import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../screens/ai_assistant/data/ai_responses.dart';
import 'suggestion_chip_list.dart';

/// Chat hoş geldiniz ekranı widget'ı - Boş state
class ChatWelcomeScreen extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const ChatWelcomeScreen({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAIIcon(context),
            const SizedBox(height: 24),
            _buildWelcomeTitle(context),
            const SizedBox(height: 12),
            _buildWelcomeSubtitle(context),
            const SizedBox(height: 32),
            SuggestionChipList(
              suggestions: AIResponses.suggestions,
              onTap: onSuggestionTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIIcon(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 60,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildWelcomeTitle(BuildContext context) {
    return Text(
      AIResponses.welcomeTitle,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWelcomeSubtitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        AIResponses.welcomeSubtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

