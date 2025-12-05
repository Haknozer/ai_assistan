import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/messages/models/message_model.dart';
import '../../../services/n8n_response_storage_service.dart';

/// AI özeti kartı widget'ı - n8n'den dönen AI önerilerini gösterir
class AiSummaryCard extends ConsumerStatefulWidget {
  final MessageModel message;

  const AiSummaryCard({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends ConsumerState<AiSummaryCard> {
  Map<String, dynamic>? _n8nResponse;
  bool _isLoading = true;
  String? _lastMessageId; // Son yüklenen mesaj ID'yi takip et

  @override
  void initState() {
    super.initState();
    _loadN8nResponse();
  }

  @override
  void didUpdateWidget(AiSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mesaj değiştiyse response'u yeniden yükle
    final currentMessageId = widget.message.id;
    final oldMessageId = oldWidget.message.id;
    
    if (currentMessageId != oldMessageId && currentMessageId != _lastMessageId) {
      _loadN8nResponse();
    }
  }

  Future<void> _loadN8nResponse() async {
    if (widget.message.id == null) {
      setState(() {
        _isLoading = false;
        _lastMessageId = null;
        _n8nResponse = null;
      });
      return;
    }

    // Aynı mesaj ise tekrar yükleme
    if (widget.message.id == _lastMessageId) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastMessageId = widget.message.id;
    });

    try {
      final response = await N8nResponseStorageService().getTelegramResponse(widget.message.id!);
      setState(() {
        _n8nResponse = response;
        _isLoading = false;
      });
    } catch (e) {
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
    if (aiSuggestions == null || aiSuggestions.isEmpty || aiSuggestions.trim().isEmpty) {
      return const SizedBox.shrink(); // Öneri yoksa gizle
    }

    return Container(
      margin: const EdgeInsets.all(16),
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
