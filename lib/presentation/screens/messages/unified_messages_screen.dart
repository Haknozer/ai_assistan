import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/responsive_utils.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_setting_provider.dart';
import 'models/message_model.dart';
import '../../widgets/messages/page_header.dart';
import '../../widgets/messages/search_and_filter_bar.dart';
import '../../widgets/messages/filter_section.dart';
import '../../widgets/messages/messages_list.dart';
import '../../widgets/messages/whatsapp_thread_panel.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../services/telegram_bot_service.dart';
import '../../../services/n8n_forwarder_service.dart';
import '../../../core/config/app_config.dart';

/// Birleşik mesajlar ekranı - Tüm platformlardan mesajları tek yerden yönetin
class UnifiedMessagesScreen extends ConsumerStatefulWidget {
  const UnifiedMessagesScreen({super.key});

  @override
  ConsumerState<UnifiedMessagesScreen> createState() => _UnifiedMessagesScreenState();
}

class _UnifiedMessagesScreenState extends ConsumerState<UnifiedMessagesScreen> {
  String _selectedFilter = 'Tümü';
  int? _selectedMessageIndex;
  String _searchQuery = '';
  bool _isLoading = false;
  List<MessageModel> _allMessages = [];
  Map<String, String> _contacts = {}; // fromNumber -> displayName
  bool _hasRequestedMessagesLoad = false;
  StreamSubscription<Map<String, dynamic>>? _telegramBotSub;
  bool _hasLoadedLocalTelegramMessages = false;

  // Menu handler için
  final int _selectedMenuIndex = 1; // Birleşik Mesajlar indeksi

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadLocalTelegramMessages();

    // Ayarları yükle ki entegrasyon durumu doğru okunabilsin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && currentUser.id != null) {
        ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);
      }
    });
  }

  @override
  void dispose() {
    _telegramBotSub?.cancel();
    super.dispose();
  }

  /// Telegram Bot API'den gelen raw update'i unified mesaja çevirir
  /// ve aynı zamanda n8n'e forward eder.
  Future<void> _handleTelegramBotUpdate(Map<String, dynamic> update) async {
    try {
      final msg = update['message'] as Map<String, dynamic>?;
      if (msg == null) return;

      final chat = msg['chat'] as Map<String, dynamic>?;
      if (chat == null) return;

      final chatIdStr = chat['id']?.toString() ?? '';
      if (chatIdStr.isEmpty) return;

      // Gösterilecek isim
      String senderName = '';
      final firstName = chat['first_name']?.toString() ?? '';
      final lastName = chat['last_name']?.toString() ?? '';
      final title = chat['title']?.toString() ?? '';
      final username = chat['username']?.toString() ?? '';

      if ((firstName + lastName).trim().isNotEmpty) {
        senderName = '$firstName $lastName'.trim();
      } else if (title.isNotEmpty) {
        senderName = title;
      } else if (username.isNotEmpty) {
        senderName = '@$username';
      } else {
        senderName = chatIdStr;
      }

      // Mesaj gövdesi
      String body = '';
      if (msg['text'] is String) {
        body = msg['text'] as String;
      } else if (msg['caption'] is String) {
        body = msg['caption'] as String;
      } else {
        body = '[Desteklenmeyen Telegram içeriği]';
      }

      // Tarih / saat
      final dateSeconds = (msg['date'] as int?) ?? 0;
      String time = '';
      String? date;
      DateTime? fullDateTime;
      if (dateSeconds > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateSeconds * 1000, isUtc: true).toLocal();
        fullDateTime = dt;
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        date = '${dt.day}.${dt.month}.${dt.year}';
      }

      final isOutgoing = msg['from']?['is_bot'] == true;

      // n8n'e forward et ve cevabı debug için al
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final n8nResponse = await N8nForwarderService().forwardTelegramMessageAndWait(
          userId: currentUser.id!.toString(),
          chatId: int.tryParse(chatIdStr) ?? 0,
          senderName: senderName,
          text: body,
          isOutgoing: isOutgoing,
          dateTime: fullDateTime,
        );
        if (kDebugMode) {
          debugPrint('n8n incoming response: $n8nResponse');
        }
      }

      // Unified listeye ekle ve lokal olarak sakla
      final newMessage = MessageModel(
        id: msg['message_id']?.toString(),
        platform: 'Telegram',
        fromNumber: chatIdStr,
        sender: senderName,
        subject: body.length > 30 ? body.substring(0, 30) : body,
        preview: body,
        content: body,
        time: time,
        date: date,
        isUnread: !isOutgoing,
        icon: Icons.telegram,
        color: Colors.blue,
        isOutgoing: isOutgoing,
      );

      setState(() {
        // Eğer daha önce optimistic olarak eklenmiş (id:null, aynı chat ve metin, yönü aynı) bir Telegram
        // mesajı varsa, onu kaldır ki gerçek update tek kopya olsun.
        _allMessages.removeWhere((m) =>
            m.platform == 'Telegram' &&
            m.id == null &&
            m.fromNumber == chatIdStr &&
            (m.content ?? m.preview) == body &&
            m.isOutgoing == isOutgoing);

        // Aynı Telegram mesajı (message_id) zaten varsa tekrar ekleme (uygulama yeniden açıldığında double göstermesin)
        final existingIndex = _allMessages.indexWhere(
          (m) => m.platform == 'Telegram' && m.id != null && m.id == newMessage.id,
        );
        if (existingIndex >= 0) {
          _allMessages[existingIndex] = newMessage;
        } else {
          _allMessages.add(newMessage);
        }
      });

      _persistLocalTelegramMessages();
    } catch (_) {
      // Sessizce yut
    }
  }

  /// Lokalden Telegram mesajlarını yükle
  Future<void> _loadLocalTelegramMessages() async {
    if (_hasLoadedLocalTelegramMessages) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('telegram_messages');
    if (raw == null || raw.isEmpty) {
      _hasLoadedLocalTelegramMessages = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final messages = decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => MessageModel.fromJson(m))
          .where((m) => m.platform == 'Telegram')
          .toList();

      setState(() {
        _allMessages.addAll(messages);
      });
    } catch (_) {
      // parse hatalarını yut
    } finally {
      _hasLoadedLocalTelegramMessages = true;
    }
  }

  /// Sadece Telegram mesajlarını lokal olarak sakla
  Future<void> _persistLocalTelegramMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final telegramMessages = _allMessages.where((m) => m.platform == 'Telegram').toList();
    final list = telegramMessages.map((m) => m.toJson()).toList();
    await prefs.setString('telegram_messages', jsonEncode(list));
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('whatsapp_contacts');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _contacts = decoded.map((k, v) => MapEntry(k, v.toString()));
      });
    } catch (_) {
      // ignore parse errors
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final client = Supabase.instance.client;
      final supabaseUser = client.auth.currentUser;
      final response = await client
          .from('messages')
          .select()
          .eq('user_id', supabaseUser!.id)
          // Eski mesajlar üstte, yeni mesajlar altta olacak şekilde kronolojik sırala
          .order('created_at', ascending: true);

      final data = response as List<dynamic>;
      final newContacts = <String, String>{};

      setState(() {
        _allMessages = data.map((row) {
          final map = row as Map<String, dynamic>;
          final id = map['id']?.toString();
          final body = (map['body'] as String?) ?? '';
          final fromNumber = map['from_number']?.toString() ?? '';
          final createdAtStr = map['created_at']?.toString();

          String time = '';
          String? date;
          if (createdAtStr != null) {
            try {
              final dt = DateTime.parse(createdAtStr).toLocal();
              time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              date = '${dt.day}.${dt.month}.${dt.year}';
            } catch (_) {
              time = createdAtStr;
              date = createdAtStr;
            }
          }

          final isRead = (map['is_read'] as bool?) ?? false;
          final isOutgoing = (map['is_outgoing'] as bool?) ?? false;

          final dbSenderName = (map['sender_name'] as String?) ?? '';

          // Eğer bu numara için daha önce lokal kayıt yoksa ve gelen bir mesajda (isOutgoing=false)
          // WhatsApp'tan bir isim geldiyse, bunu otomatik olarak lokal kontaklara ekle.
          if (!isOutgoing && dbSenderName.isNotEmpty && !_contacts.containsKey(fromNumber)) {
            newContacts[fromNumber] = dbSenderName;
          }

          // Önce lokal kişi adı varsa onu kullan (yeni eklenenler dahil)
          final localName = _contacts[fromNumber] ?? newContacts[fromNumber];
          String senderName;
          if (localName != null && localName.isNotEmpty) {
            senderName = localName;
          } else if (!isOutgoing && dbSenderName.isNotEmpty) {
            // Gelen mesajlarda veritabanındaki adı kullan
            senderName = dbSenderName;
          } else {
            // Aksi halde numarayı göster
            senderName = fromNumber.isNotEmpty ? fromNumber : 'Bilinmeyen';
          }

          return MessageModel(
            id: id,
            platform: 'WhatsApp',
            fromNumber: fromNumber,
            sender: senderName,
            subject: body.length > 30 ? body.substring(0, 30) : body,
            preview: body,
            content: body,
            time: time,
            date: date,
            isUnread: !isRead,
            icon: Icons.message,
            color: Colors.green,
            isOutgoing: isOutgoing,
          );
        }).toList();
        _isLoading = false;
      });

      // Yeni keşfedilen kişiler varsa, bunları persiste et ve state'e yaz
      if (newContacts.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final merged = {..._contacts, ...newContacts};
        await prefs.setString('whatsapp_contacts', jsonEncode(merged));
        setState(() {
          _contacts = merged;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Filtrelenmiş mesaj listesini döndürür
  List<MessageModel> get _filteredMessages {
    // Aynı numaradan gelen mesajları tek bir sohbet olarak grupla.
    // En GÜNCEL mesaj temsilci olsun diye sondan başlayarak bakıyoruz.
    final seenNumbers = <String>{};
    final List<MessageModel> conversations = [];
    for (final msg in _allMessages.reversed) {
      if (!seenNumbers.contains(msg.fromNumber)) {
        seenNumbers.add(msg.fromNumber);
        conversations.add(msg);
      }
    }

    // Son eklenen ilk oldu; listeyi tekrar çevir ki üstte daha eski sohbetler kalsın.
    List<MessageModel> messages = List.from(conversations.reversed);

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      messages = messages.where((message) {
        return message.sender.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            message.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            message.preview.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Platform ve durum filtresi
    if (_selectedFilter != 'Tümü') {
      if (_selectedFilter == 'Okunmamış') {
        messages = messages.where((message) => message.isUnread).toList();
      } else {
        messages = messages.where((message) => message.platform == _selectedFilter).toList();
      }
    }

    return messages;
  }

  /// Seçili mesajı döndürür
  MessageModel? get _selectedMessage {
    if (_selectedMessageIndex == null || _selectedMessageIndex! >= _filteredMessages.length) {
      return null;
    }
    return _filteredMessages[_selectedMessageIndex!];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Kullanıcının WhatsApp ve Telegram entegrasyonu bağlı mı kontrol et
    final userSettingsAsync = ref.watch(currentUserSettingsNotifierProvider);
    final isWhatsappConnected = userSettingsAsync.when(
      data: (settings) {
        try {
          final setting = settings.firstWhere((s) => s.settingKey == 'whatsapp_connected');
          return setting.getBoolValue();
        } catch (_) {
          return false;
        }
      },
      loading: () => false,
      error: (_, __) => false,
    );

    final isTelegramConnected = userSettingsAsync.when(
      data: (settings) {
        try {
          final setting = settings.firstWhere((s) => s.settingKey == 'telegram_connected');
          return setting.getBoolValue();
        } catch (_) {
          return false;
        }
      },
      loading: () => false,
      error: (_, __) => false,
    );

    // Telegram Bot polling'i sadece entegrasyon açıksa başlat
    // Ama sadece ayarlar yüklendiyse (loading değilse) başlat
    final userSettingsState = userSettingsAsync;
    if (userSettingsState.hasValue) {
      if (isTelegramConnected && _telegramBotSub == null) {
        final botService = TelegramBotService();
        if (botService.isConfigured && AppConfig.enableTelegramPolling) {
          // Önce listener'ı kur (update'leri dinlemeye başla)
          _telegramBotSub = botService.updatesStream.listen((update) {
            _handleTelegramBotUpdate(update);
          });
          // Sonra bekleyen update'leri çek (entegrasyon kapalıyken gelen mesajlar)
          botService.fetchPendingUpdates().then((_) {
            // Sonra periyodik polling'i başlat
            botService.startPolling();
          }).catchError((e) {
            // Hata olsa bile polling'i başlat
            botService.startPolling();
          });
        }
      } else if (!isTelegramConnected && _telegramBotSub != null) {
        // Entegrasyon kapalıysa polling'i durdur
        _telegramBotSub?.cancel();
        _telegramBotSub = null;
        TelegramBotService().stopPolling();
      }
    }

    // Bağlantı AÇIK ve henüz mesajlar için istek atılmadıysa, mesajları Supabase'ten çek
    if (isWhatsappConnected && !_hasRequestedMessagesLoad) {
      _hasRequestedMessagesLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMessages();
      });
    }

    // Bağlantı KAPALI ise, ilgili platform mesajlarını temizle ve tekrar yükleme.
    final hasWhatsappMessages = _allMessages.any((m) => m.platform == 'WhatsApp');
    if (!isWhatsappConnected && (_hasRequestedMessagesLoad || hasWhatsappMessages)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // Sadece WhatsApp platformundaki mesajları sil
          _allMessages = _allMessages.where((m) => m.platform != 'WhatsApp').toList();
          _hasRequestedMessagesLoad = false;
          _isLoading = false;

          // Eğer seçili mesaj WhatsApp ise, seçimi sıfırla
          final selected = _selectedMessage;
          if (selected != null && selected.platform == 'WhatsApp') {
            _selectedMessageIndex = null;
          }
        });
      });
    }

    // Telegram entegrasyonu KAPALI ise, Telegram mesajlarını temizle
    // Ama sadece ayarlar yüklendiyse (loading değilse) temizle
    final hasTelegramMessages = _allMessages.any((m) => m.platform == 'Telegram');
    if (userSettingsState.hasValue && !isTelegramConnected && hasTelegramMessages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // Sadece Telegram platformundaki mesajları sil
          _allMessages = _allMessages.where((m) => m.platform != 'Telegram').toList();

          // Eğer seçili mesaj Telegram ise, seçimi sıfırla
          final selected = _selectedMessage;
          if (selected != null && selected.platform == 'Telegram') {
            _selectedMessageIndex = null;
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
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
                    // Başlık ve Okunmamış Sayısı
                    PageHeader(
                      unreadCount: _allMessages.where((m) => m.isUnread).length,
                    ),

                    const SizedBox(height: 24),

                    // Arama ve Filtrele
                    SearchAndFilterBar(
                      onSearchChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                          _selectedMessageIndex = null; // Arama yapılınca seçimi sıfırla
                        });
                      },
                      onFilterTap: () {
                        // TODO: Implement advanced filter dialog
                      },
                    ),

                    const SizedBox(height: 16),

                    // Filtreler
                    FilterSection(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                          _selectedMessageIndex = null; // Filtre değişince seçimi sıfırla
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // İki Panelli Düzen (Liste + Detay)
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol Panel - Mesaj Listesi
                                    Expanded(
                                      flex: 4,
                                      child: MessagesList(
                                        messages: _filteredMessages,
                                        selectedIndex: _selectedMessageIndex,
                                        onMessageSelected: (index) async {
                                          final message = _filteredMessages[index];

                                          // Okunmamışsa Supabase'te is_read = true yap
                                          if (message.isUnread && message.id != null) {
                                            try {
                                              final client = Supabase.instance.client;
                                              final res = await client
                                                  .from('messages')
                                                  .update({'is_read': true}).eq('id', message.id!);

                                              // Debug: güncelleme sonucu
                                              // // ignore: avoid_print
                                              print('UPDATE messages.is_read result (desktop): $res');

                                              // Local state'i de güncelle
                                              setState(() {
                                                _allMessages = _allMessages.map((m) {
                                                  if (m.id == message.id) {
                                                    return m.copyWith(isUnread: false);
                                                  }
                                                  return m;
                                                }).toList();
                                                _selectedMessageIndex = index;
                                              });
                                            } catch (e) {
                                              // // ignore: avoid_print
                                              print('UPDATE messages.is_read error (desktop): $e');
                                              setState(() {
                                                _selectedMessageIndex = index;
                                              });
                                            }
                                          } else {
                                            setState(() {
                                              _selectedMessageIndex = index;
                                            });
                                          }
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Sağ Panel - Sohbet detayı (WhatsApp / Telegram)
                                    Expanded(
                                      flex: 6,
                                      child: WhatsAppThreadPanel(
                                        selectedMessage: _selectedMessage,
                                        allMessages: _allMessages,
                                        onEditContact: _handleEditContact,
                                        // WhatsApp için entegrasyon durumuna göre, Telegram için her zaman gönderime izin ver
                                        canSend: _selectedMessage?.platform == 'WhatsApp' ? isWhatsappConnected : true,
                                        currentUserId: currentUser.id?.toString(),
                                        // Telegram mesajları değiştiğinde lokal persist et
                                        onTelegramMessagesChanged: _persistLocalTelegramMessages,
                                      ),
                                    ),
                                  ],
                                )
                              : MessagesList(
                                  messages: _filteredMessages,
                                  selectedIndex: _selectedMessageIndex,
                                  onMessageSelected: (index) async {
                                    final message = _filteredMessages[index];

                                    if (message.isUnread && message.id != null) {
                                      try {
                                        final client = Supabase.instance.client;
                                        final res = await client
                                            .from('messages')
                                            .update({'is_read': true}).eq('id', message.id!);

                                        // Debug: güncelleme sonucu
                                        // // ignore: avoid_print
                                        print('UPDATE messages.is_read result (mobile): $res');

                                        setState(() {
                                          _allMessages = _allMessages.map((m) {
                                            if (m.id == message.id) {
                                              return m.copyWith(isUnread: false);
                                            }
                                            return m;
                                          }).toList();
                                          _selectedMessageIndex = index;
                                        });
                                      } catch (e) {
                                        // // ignore: avoid_print
                                        print('UPDATE messages.is_read error (mobile): $e');
                                        setState(() {
                                          _selectedMessageIndex = index;
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        _selectedMessageIndex = index;
                                      });
                                    }

                                    // Mobilde mesaj detayına git (ileride ayrı sayfaya yönlendirilebilir)
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(int index) {
    if (index == 1) {
      // Birleşik Mesajlar zaten buradayız, bir şey yapma
      return;
    }

    // Diğer menü öğelerine git
    switch (index) {
      case 0: // Ana Sayfa
        context.go('/home');
        break;
      case 2: // Görevler
        context.go('/tasks');
        break;
      case 3: // Takvim
        context.go('/calendar');
        break;
      case 4: // E-Posta
        context.go('/email');
        break;
      case 5: // Analitik
        context.go('/analytics');
        break;
      case 6: // AI Asistan
        context.go('/ai-assistant');
        break;
      case 7: // Komut Paleti
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
      case 8:
        context.go('/settings');
        break;
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  Future<void> _handleEditContact(String phoneNumber, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final currentRaw = prefs.getString('whatsapp_contacts');
    Map<String, dynamic> map = {};
    if (currentRaw != null && currentRaw.isNotEmpty) {
      try {
        map = jsonDecode(currentRaw) as Map<String, dynamic>;
      } catch (_) {
        map = {};
      }
    }
    map[phoneNumber] = displayName;
    await prefs.setString('whatsapp_contacts', jsonEncode(map));

    setState(() {
      _contacts[phoneNumber] = displayName;
      _allMessages = _allMessages.map((m) {
        if (m.fromNumber == phoneNumber) {
          return m.copyWith(sender: displayName);
        }
        return m;
      }).toList();
    });
  }
}
