import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';
import '../../../services/n8n_response_storage_service.dart';
import '../../../core/utils/logger.dart';

/// Email için AI önerileri kartı - n8n'den dönen AI önerilerini gösterir
class EmailAiSuggestionsCard extends ConsumerStatefulWidget {
  final Email email;

  const EmailAiSuggestionsCard({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailAiSuggestionsCard> createState() => _EmailAiSuggestionsCardState();
}

class _EmailAiSuggestionsCardState extends ConsumerState<EmailAiSuggestionsCard> {
  Map<String, dynamic>? _n8nResponse;
  bool _isLoading = true;
  String? _lastEmailId; // Son yüklenen email ID'yi takip et

  @override
  void initState() {
    super.initState();
    _loadN8nResponse();
  }

  @override
  void didUpdateWidget(EmailAiSuggestionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Email değiştiyse response'u yeniden yükle
    final currentEmailId = widget.email.messageId ?? widget.email.id?.toString() ?? '';
    final oldEmailId = oldWidget.email.messageId ?? oldWidget.email.id?.toString() ?? '';
    
    if (currentEmailId != oldEmailId && currentEmailId != _lastEmailId) {
      _loadN8nResponse();
    }
  }

  Future<void> _loadN8nResponse() async {
    final emailId = widget.email.messageId ?? widget.email.id?.toString() ?? '';
    if (emailId.isEmpty) {
      setState(() {
        _isLoading = false;
        _lastEmailId = null;
        _n8nResponse = null;
      });
      return;
    }

    // Aynı email ise tekrar yükleme
    if (emailId == _lastEmailId) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastEmailId = emailId;
    });

    try {
      final response = await N8nResponseStorageService().getEmailResponse(emailId);
      
      // Debug: Response formatını logla
      AppLogger.debug('EmailAiSuggestionsCard - Loaded response: $response', 'N8N');
      
      setState(() {
        _n8nResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('EmailAiSuggestionsCard - Error loading response', tag: 'N8N', error: e);
      setState(() {
        _isLoading = false;
        _n8nResponse = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // n8n response yoksa veya yükleniyorsa göster
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_n8nResponse == null) {
      return const SizedBox.shrink(); // Response yoksa gizle
    }

    final aiSuggestions = N8nResponseStorageService().extractAiSuggestions(_n8nResponse);
    
    // Debug: Extract edilen suggestions'ı logla
    AppLogger.debug('EmailAiSuggestionsCard - Extracted suggestions: $aiSuggestions', 'N8N');
    
    if (aiSuggestions == null || aiSuggestions.isEmpty || aiSuggestions.trim().isEmpty) {
      return const SizedBox.shrink(); // Öneri yoksa gizle
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Önerileri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiSuggestions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

