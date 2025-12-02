import 'package:flutter/material.dart';
import '../../screens/messages/models/message_model.dart';
import 'empty_message_state.dart';
import '../../../services/whatsapp_service.dart';

/// WhatsApp tarzı sohbet paneli - Seçilen kişi (from_number) için tüm mesajları gösterir.
class WhatsAppThreadPanel extends StatefulWidget {
  final MessageModel? selectedMessage;
  final List<MessageModel> allMessages;
  final Future<void> Function(String phoneNumber, String displayName)? onEditContact;

  const WhatsAppThreadPanel({
    super.key,
    required this.selectedMessage,
    required this.allMessages,
    this.onEditContact,
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
          _buildHeader(context, widget.selectedMessage!),
          const Divider(height: 1),
          // Mesajlar (sohbet baloncukları)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: threadMessages.length,
              itemBuilder: (context, index) {
                // Mesajlar zaten kronolojik (eski -> yeni) sıralı; index 0 en eski, son index en yeni (altta)
                final msg = threadMessages[index];
                final isMe = msg.isOutgoing;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bubbleColor = isMe
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? const Color(0xFF303030) : Colors.grey[200]!);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    constraints: BoxConstraints(
                      // Baloncuk genişliğini belirgin şekilde dar tut (WhatsApp benzeri)
                      maxWidth: MediaQuery.of(context).size.width * 0.10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content ?? msg.preview,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                // Yazı boyutunu biraz daha büyüt
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg.time,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Mesaj yazma alanı
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MessageModel message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: message.color,
            child: Text(
              message.getInitials(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.sender,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onEditContact != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'İsmi düzenle',
                        onPressed: () => _showEditNameDialog(context, message),
                      ),
                  ],
                ),
                Text(
                  message.fromNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Mesaj yaz...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : _handleSend,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.selectedMessage == null) return;

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
    } catch (_) {
      // Şimdilik hata gösterme, sadece loading'i kapat
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
