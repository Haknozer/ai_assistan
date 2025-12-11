import 'package:flutter/material.dart';

import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/n8n_forwarder_service.dart';
import '../../../../services/n8n_response_storage_service.dart';
import '../../../../services/telegram_bot_service.dart';
import '../../../screens/messages/models/message_model.dart';
import 'forwarded_sent_store.dart';

class TelegramSendResult {
  TelegramSendResult({
    required this.optimisticMessage,
    this.forwarded = false,
  });

  final MessageModel optimisticMessage;
  final bool forwarded;
}

class TelegramMessageSender {
  /// Telegram mesajını gönderir, n8n forward eder, optimistic message üretir.
  /// - `forwardedSentMessages`: var olan set, yeni key eklenirse güncelleyip kaydeder.
  /// - `currentUserId`: n8n forward için gerekli.
  static Future<TelegramSendResult?> send({
    required BuildContext context,
    required String text,
    required MessageModel selectedMessage,
    required String? currentUserId,
    required Set<String> forwardedSentMessages,
    required ForwardedSentStore forwardedStore,
  }) async {
    final telegramService = TelegramBotService();
    if (!telegramService.isConfigured) {
      ErrorHandler.showInfo(context, 'Telegram bot yapılandırılmamış. Bot token kontrol edin.');
      return null;
    }

    final chatId = int.tryParse(selectedMessage.fromNumber);
    if (chatId == null) {
      ErrorHandler.showInfo(context, 'Geçersiz Telegram chat id.');
      return null;
    }

    await telegramService.sendMessage(chatId: chatId, text: text);

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    bool forwarded = false;
    if (currentUserId != null) {
      final sentMessageKey = '${now.millisecondsSinceEpoch}_${text.hashCode}';
      if (!forwardedSentMessages.contains(sentMessageKey)) {
        final n8nResponse = await N8nForwarderService().forwardTelegramMessageAndWait(
          userId: currentUserId,
          chatId: chatId,
          senderName: selectedMessage.sender,
          text: text,
          isOutgoing: true,
          dateTime: now,
        );

        AppLogger.debug('n8n response: $n8nResponse', 'N8N');

        if (n8nResponse != null) {
          await N8nResponseStorageService().saveTelegramResponse(sentMessageKey, n8nResponse);
        }

        forwardedSentMessages.add(sentMessageKey);
        await forwardedStore.save(forwardedSentMessages);

        if (n8nResponse != null && context.mounted) {
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
        forwarded = true;
      }
    }

    final optimistic = MessageModel(
      id: null,
      platform: 'Telegram',
      fromNumber: selectedMessage.fromNumber,
      sender: selectedMessage.sender,
      subject: text.length > 30 ? text.substring(0, 30) : text,
      preview: text,
      content: text,
      time: timeStr,
      date: null,
      isUnread: false,
      icon: Icons.telegram,
      color: Colors.blue,
      isOutgoing: true,
    );

    return TelegramSendResult(
      optimisticMessage: optimistic,
      forwarded: forwarded,
    );
  }
}

