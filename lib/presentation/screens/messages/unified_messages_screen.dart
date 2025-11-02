import 'package:flutter/material.dart';
import '../../../utils/responsive_utils.dart';
import 'data/mock_messages.dart';
import 'models/message_model.dart';
import 'widgets/page_header.dart';
import 'widgets/search_and_filter_bar.dart';
import 'widgets/filter_section.dart';
import 'widgets/messages_list.dart';
import 'widgets/message_detail_panel.dart';

/// Birleşik mesajlar ekranı - Tüm platformlardan mesajları tek yerden yönetin
class UnifiedMessagesScreen extends StatefulWidget {
  const UnifiedMessagesScreen({super.key});

  @override
  State<UnifiedMessagesScreen> createState() => _UnifiedMessagesScreenState();
}

class _UnifiedMessagesScreenState extends State<UnifiedMessagesScreen> {
  String _selectedFilter = 'Tümü';
  int? _selectedMessageIndex;
  String _searchQuery = '';

  /// Filtrelenmiş mesaj listesini döndürür
  List<MessageModel> get _filteredMessages {
    List<MessageModel> messages = MockMessages.messages;

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
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve Okunmamış Sayısı
              PageHeader(
                unreadCount: MockMessages.unreadCount,
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
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol Panel - Mesaj Listesi
                          Expanded(
                            flex: 4,
                            child: MessagesList(
                              messages: _filteredMessages,
                              selectedIndex: _selectedMessageIndex,
                              onMessageSelected: (index) {
                                setState(() {
                                  _selectedMessageIndex = index;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Sağ Panel - Mesaj Detayı
                          Expanded(
                            flex: 6,
                            child: MessageDetailPanel(
                              message: _selectedMessage,
                            ),
                          ),
                        ],
                      )
                    : MessagesList(
                        messages: _filteredMessages,
                        selectedIndex: _selectedMessageIndex,
                        onMessageSelected: (index) {
                          setState(() {
                            _selectedMessageIndex = index;
                          });
                          // Mobilde mesaj detayına git
                          // TODO: Navigate to detail screen
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
