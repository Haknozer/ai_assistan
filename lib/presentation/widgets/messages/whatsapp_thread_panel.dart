import 'package:flutter/material.dart';
import '../../screens/messages/models/message_model.dart';
import 'empty_message_state.dart';
import '../../../services/whatsapp_service.dart';
import '../../../services/telegram_bot_service.dart';
import '../../../services/n8n_forwarder_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/error_handler.dart';
import 'whatsapp/whatsapp_thread_header.dart';
import 'whatsapp/whatsapp_message_list.dart';
import 'whatsapp/whatsapp_input_area.dart';

/// WhatsApp tarzı sohbet paneli - Seçilen kişi (from_number) için tüm mesajları gösterir.
class WhatsAppThreadPanel extends StatefulWidget {
  final MessageModel? selectedMessage;
  final List<MessageModel> allMessages;
  final Future<void> Function(String phoneNumber, String displayName)? onEditContact;
  final bool canSend;
  final String? currentUserId;
  // Telegram mesajları değiştiğinde (örneğin optimistic olarak yeni mesaj eklendiğinde)
  // üst seviyeye haber vermek için callback. Üst seviye bu sayede lokal persist işlemi yapabilir.
  final Future<void> Function()? onTelegramMessagesChanged;

  const WhatsAppThreadPanel({
    super.key,
    required this.selectedMessage,
    required this.allMessages,
    this.onEditContact,
    this.canSend = true,
    this.currentUserId,
    this.onTelegramMessagesChanged,
  });

  @override
  State<WhatsAppThreadPanel> createState() => _WhatsAppThreadPanelState();
}

class _WhatsAppThreadPanelState extends State<WhatsAppThreadPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mesaj seçilmediyse boş durum göster
    if (widget.selectedMessage == null) {
      return const EmptyMessageState();
    }

    // Aynı kullanıcıya ait tüm mesajları (fromNumber) filtrele
    final threadMessages = widget.allMessages.where((m) => m.fromNumber == widget.selectedMessage!.fromNumber).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Üst başlık (kişi adı ve numarası)
          WhatsAppThreadHeader(
            message: widget.selectedMessage!,
            onEditPressed:
                widget.onEditContact != null ? () => _showEditNameDialog(context, widget.selectedMessage!) : null,
          ),
          const Divider(height: 1),
          // Mesajlar (sohbet baloncukları)
          Expanded(
            child: WhatsAppMessageList(messages: threadMessages),
          ),
          const Divider(height: 1),
          // Mesaj yazma alanı
          WhatsAppInputArea(
            controller: _controller,
            isSending: _isSending,
            canSend: widget.canSend,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.selectedMessage == null) return;

    final platform = widget.selectedMessage!.platform;

    // Telegram sohbeti ise Telegram üzerinden gönder
    if (platform == 'Telegram') {
      setState(() {
        _isSending = true;
      });

      try {
        final telegramService = TelegramBotService();
        if (!telegramService.isConfigured) {
          ErrorHandler.showInfo(context, 'Telegram bot yapılandırılmamış. Bot token kontrol edin.');
          return;
        }

        final chatId = int.tryParse(widget.selectedMessage!.fromNumber);
        if (chatId == null) {
          ErrorHandler.showInfo(context, 'Geçersiz Telegram chat id.');
          return;
        }

        await telegramService.sendMessage(
          chatId: chatId,
          text: text,
        );

        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        // Gönderdiğimiz mesajı da n8n'e ilet ve cevabı almak istersek burada yakalayabiliriz.
        if (widget.currentUserId != null) {
          final n8nResponse = await N8nForwarderService().forwardTelegramMessageAndWait(
            userId: widget.currentUserId!,
            chatId: chatId,
            senderName: widget.selectedMessage!.sender,
            text: text,
            isOutgoing: true,
            dateTime: now,
          );

          AppLogger.debug('n8n response: $n8nResponse', 'N8N');

          // Şimdilik debug amaçlı olarak cevabı ekranda göster.
          if (mounted && n8nResponse != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  n8nResponse.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        // Telegram için optimistic UI: hemen sağ tarafta kendi gönderdiğimiz mesajı göster
        setState(() {
          widget.allMessages.add(
            MessageModel(
              id: null,
              platform: 'Telegram',
              fromNumber: widget.selectedMessage!.fromNumber,
              sender: widget.selectedMessage!.sender,
              subject: text.length > 30 ? text.substring(0, 30) : text,
              preview: text,
              content: text,
              time: timeStr,
              date: null,
              isUnread: false,
              icon: Icons.telegram,
              color: Colors.blue,
              isOutgoing: true,
            ),
          );
          _controller.clear();
        });

        // Lokal persist işlemi için üst seviyeyi bilgilendir
        if (widget.onTelegramMessagesChanged != null) {
          await widget.onTelegramMessagesChanged!();
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.handleError(
            context,
            e,
            tag: 'Telegram',
            onRetry: () => _handleSend(),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }

      return;
    }

    // WhatsApp için mevcut davranış
    if (!widget.canSend) {
      ErrorHandler.showInfo(context, 'WhatsApp entegrasyonu kapalı. Önce Ayarlar > Entegrasyonlar\'dan bağlayın.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final whatsappService = WhatsAppService();
      await whatsappService.sendMessage(
        toNumber: widget.selectedMessage!.fromNumber,
        body: text,
        store: true,
      );

      // Local olarak hemen göster (optimistic UI)
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        widget.allMessages.add(
          MessageModel(
            id: null,
            platform: 'WhatsApp',
            fromNumber: widget.selectedMessage!.fromNumber,
            // Liste ve başlıkta her zaman karşı tarafın adı/numarası görünsün
            // bu yüzden optimistic kayıt için de mevcut sender bilgisini kullanıyoruz.
            sender: widget.selectedMessage!.sender,
            subject: text.length > 30 ? text.substring(0, 30) : text,
            preview: text,
            content: text,
            time: timeStr,
            date: null,
            isUnread: false,
            icon: Icons.message,
            color: Theme.of(context).colorScheme.primary,
            isOutgoing: true,
          ),
        );
        _controller.clear();
      });
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ErrorHandler.handleError(
          context,
          e,
          tag: 'WhatsApp',
          onRetry: () => _handleSend(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, MessageModel message) async {
    final controller = TextEditingController(text: message.sender);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kişi adını düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Görünen ad',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || widget.onEditContact == null) return;

    await widget.onEditContact!(message.fromNumber, result);

    // Lokal state'teki mesajların sender alanını da güncelle
    setState(() {
      for (var i = 0; i < widget.allMessages.length; i++) {
        final m = widget.allMessages[i];
        if (m.fromNumber == message.fromNumber) {
          widget.allMessages[i] = m.copyWith(sender: result);
        }
      }
    });
  }
}
