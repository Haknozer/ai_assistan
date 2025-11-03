import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/responsive_utils.dart';
import '../../../providers/user_provider.dart';
import 'data/mock_messages.dart';
import 'models/message_model.dart';
import '../../widgets/messages/page_header.dart';
import '../../widgets/messages/search_and_filter_bar.dart';
import '../../widgets/messages/filter_section.dart';
import '../../widgets/messages/messages_list.dart';
import '../../widgets/messages/message_detail_panel.dart';
import '../../widgets/layout/side_menu.dart';

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

  // Menu handler için
  final int _selectedMenuIndex = 1; // Birleşik Mesajlar indeksi

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
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }
}
