import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/email.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import 'data/mock_emails.dart';
import '../../widgets/email/email_page_header.dart';
import '../../widgets/email/search_and_filter_bar.dart';
import '../../widgets/email/email_filter_section.dart';
import '../../widgets/email/email_list.dart';
import '../../widgets/email/email_detail_panel.dart';
import '../../widgets/email/compose_email_dialog.dart';

/// E-posta ekranı - E-posta yönetimi ve filtreleme
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  String _selectedFilter = 'Tümü';
  int? _selectedEmailIndex;
  String _searchQuery = '';
  final int _selectedMenuIndex = 4; // E-Posta indeksi

  // Mock e-posta verileri
  late List<Email> _emails;

  @override
  void initState() {
    super.initState();
    _emails = List.from(MockEmails.emails);
  }

  /// Filtrelenmiş e-posta listesini döndürür
  List<Email> get _filteredEmails {
    List<Email> emails = _emails;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      emails = emails.where((email) {
        return email.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.fromDisplayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.contentPreview.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // E-posta filtresi
    switch (_selectedFilter) {
      case 'Tümü':
        return emails;
      case 'Okunmamış':
        return emails.where((email) => email.isUnread).toList();
      case 'Önemli':
        return emails.where((email) => email.importance == EmailImportance.important).toList();
      case 'İş':
        return emails.where((email) => email.accountId == 1).toList(); // TODO: Account enum eklenince düzeltilecek
      case 'Spam':
        return emails.where((email) => email.isSpam).toList();
      case 'Gönderilen':
        return emails.where((email) => email.status == EmailStatus.sent).toList();
      case 'Taslak':
        return emails.where((email) => email.status == EmailStatus.draft).toList();
      default:
        return emails;
    }
  }

  /// Seçili e-postayı döndürür
  Email? get _selectedEmail {
    if (_selectedEmailIndex == null || _selectedEmailIndex! >= _filteredEmails.length) {
      return null;
    }
    return _filteredEmails[_selectedEmailIndex!];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(currentUser, padding, isDesktop),
    );
  }

  Widget _buildResponsiveLayout(dynamic currentUser, EdgeInsets padding, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, padding);
    } else {
      return _buildMobileLayout(currentUser, padding);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(dynamic currentUser, EdgeInsets padding) {
    return Row(
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
                  // Sayfa Başlığı ve İstatistikler
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: EmailPageHeader(
                      totalEmails: _emails.length,
                      unreadEmails: MockEmails.unreadCount,
                    ),
                  ),

                  // Arama ve Filtrele
                  SearchAndFilterBar(
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                        _selectedEmailIndex = null; // Arama yapılınca seçimi sıfırla
                      });
                    },
                    onComposeEmail: _showComposeEmailDialog,
                  ),

                  const SizedBox(height: 16),

                  // E-posta Filtreleri
                  EmailFilterSection(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                        _selectedEmailIndex = null; // Filtre değişince seçimi sıfırla
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // İki Panelli Düzen (Liste + Detay)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sol Panel - E-posta Listesi
                        Expanded(
                          flex: 4,
                          child: EmailList(
                            emails: _filteredEmails,
                            selectedIndex: _selectedEmailIndex,
                            onEmailSelected: (index) {
                              setState(() {
                                _selectedEmailIndex = index;
                                // E-postayı okundu olarak işaretle
                                if (_selectedEmail?.status == EmailStatus.unread) {
                                  _markAsRead(_selectedEmail!);
                                }
                              });
                            },
                            onDeleteEmail: _deleteEmail,
                            onMarkAsImportant: _markAsImportant,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Sağ Panel - E-posta Detayı
                        Expanded(
                          flex: 6,
                          child: EmailDetailPanel(
                            email: _selectedEmail,
                            onReply: _replyToEmail,
                            onForward: _forwardEmail,
                            onDelete: _deleteEmail,
                            onMarkAsImportant: _markAsImportant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout - AppBar + Drawer + içerik
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Mobil AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                ),
              ),
              child: EmailPageHeader(
                totalEmails: _emails.length,
                unreadEmails: MockEmails.unreadCount,
                isDesktop: false,
              ),
            ),

            // Mobil İçerik
            Expanded(
              child: Padding(
                padding: padding.copyWith(top: 16),
                child: Column(
                  children: [
                    SearchAndFilterBar(
                      onSearchChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                          _selectedEmailIndex = null;
                        });
                      },
                      onComposeEmail: _showComposeEmailDialog,
                    ),
                    const SizedBox(height: 16),
                    EmailFilterSection(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                          _selectedEmailIndex = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: EmailList(
                        emails: _filteredEmails,
                        selectedIndex: _selectedEmailIndex,
                        onEmailSelected: (index) {
                          setState(() {
                            _selectedEmailIndex = index;
                            if (_selectedEmail?.status == EmailStatus.unread) {
                              _markAsRead(_selectedEmail!);
                            }
                          });
                          // Mobilde e-posta detayına git
                          // TODO: Navigate to email detail screen
                        },
                        onDeleteEmail: _deleteEmail,
                        onMarkAsImportant: _markAsImportant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: _selectedMenuIndex,
          onMenuTap: (index) {
            Navigator.pop(context);
            _handleMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context);
            _handleProfileTap();
          },
        ),
      ),
    );
  }

  void _handleMenuTap(int index) {
    if (index == 4) return; // Zaten e-posta sayfasındayız

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/messages');
        break;
      case 2:
        context.go('/tasks');
        break;
      case 3:
        context.go('/calendar');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 6:
        context.go('/ai-assistant');
        break;
      case 7:
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

  void _markAsRead(Email email) {
    setState(() {
      final emailIndex = _emails.indexWhere((e) => e.id == email.id);
      if (emailIndex != -1) {
        _emails[emailIndex] = _emails[emailIndex].copyWith(
          status: EmailStatus.read,
        );
      }
    });
  }

  void _markAsImportant(Email email) {
    setState(() {
      final emailIndex = _emails.indexWhere((e) => e.id == email.id);
      if (emailIndex != -1) {
        final currentImportance = _emails[emailIndex].importance;
        _emails[emailIndex] = _emails[emailIndex].copyWith(
          importance:
              currentImportance == EmailImportance.important ? EmailImportance.normal : EmailImportance.important,
        );
      }
    });
  }

  void _deleteEmail(Email email) {
    setState(() {
      _emails.removeWhere((e) => e.id == email.id);
      _selectedEmailIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-posta silindi')),
    );
  }

  void _replyToEmail(Email email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${email.fromDisplayName} yanıtlanıyor...')),
    );
  }

  void _forwardEmail(Email email) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-posta yönlendiriliyor...')),
    );
  }

  void _showComposeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => ComposeEmailDialog(
        onEmailSent: (email) {
          setState(() {
            _emails.insert(0, email);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-posta başarıyla gönderildi'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
