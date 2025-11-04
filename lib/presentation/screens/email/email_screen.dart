import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/email.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../features/email/providers/email_provider.dart';
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

  /// Seçili klasörü döndürür
  String? get _selectedFolder {
    switch (_selectedFilter) {
      case 'Gönderilen':
        return 'sent';
      case 'Taslak':
        return 'drafts';
      case 'Spam':
        return 'spam';
      default:
        return null; // null = inbox
    }
  }

  /// Email listesi parametreleri
  EmailListParams get _emailParams {
    return EmailListParams(
      folder: _selectedFolder,
    );
  }

  /// Filtrelenmiş e-posta listesini döndürür
  List<Email> _getFilteredEmails(List<Email> emails) {
    List<Email> filtered = emails;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((email) {
        return email.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.fromDisplayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.contentPreview.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // UI filtreleri (folder zaten API'den geliyor)
    switch (_selectedFilter) {
      case 'Tümü':
        return filtered;
      case 'Okunmamış':
        return filtered.where((email) => email.isUnread).toList();
      case 'Önemli':
        return filtered.where((email) => email.importance == EmailImportance.important).toList();
      case 'Spam':
        return filtered.where((email) => email.isSpam).toList();
      case 'Gönderilen':
      case 'Taslak':
        return filtered; // Folder zaten filtrelenmiş
      default:
        return filtered;
    }
  }

  /// Seçili e-postayı döndürür
  Email? _getSelectedEmail(List<Email> emails) {
    final filtered = _getFilteredEmails(emails);
    if (_selectedEmailIndex == null || _selectedEmailIndex! >= filtered.length) {
      return null;
    }
    return filtered[_selectedEmailIndex!];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final emailsAsync = ref.watch(emailNotifierProvider(_emailParams));
    final emailNotifier = ref.read(emailNotifierProvider(_emailParams).notifier);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return emailsAsync.when(
      data: (emails) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: () => emailNotifier.refresh(),
          child: _buildResponsiveLayout(currentUser, emails, emailNotifier, padding, isDesktop),
        ),
      ),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('E-posta yüklenirken hata oluştu'),
              const SizedBox(height: 8),
              Text(error.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => emailNotifier.refresh(),
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
    dynamic currentUser,
    List<Email> emails,
    EmailNotifier emailNotifier,
    EdgeInsets padding,
    bool isDesktop,
  ) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, emails, emailNotifier, padding);
    } else {
      return _buildMobileLayout(currentUser, emails, emailNotifier, padding);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(
    dynamic currentUser,
    List<Email> emails,
    EmailNotifier emailNotifier,
    EdgeInsets padding,
  ) {
    final filteredEmails = _getFilteredEmails(emails);
    final selectedEmail = _getSelectedEmail(emails);
    final unreadCount = emails.where((e) => e.isUnread).length;

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
                      totalEmails: emails.length,
                      unreadEmails: unreadCount,
                    ),
                  ),

                  // Arama ve Filtrele
                  SearchAndFilterBar(
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                        _selectedEmailIndex = null;
                      });
                    },
                    onComposeEmail: () => _showComposeEmailDialog(emailNotifier),
                  ),

                  const SizedBox(height: 16),

                  // E-posta Filtreleri
                  EmailFilterSection(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                        _selectedEmailIndex = null;
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
                            emails: filteredEmails,
                            selectedIndex: _selectedEmailIndex,
                            onEmailSelected: (index) {
                              setState(() {
                                _selectedEmailIndex = index;
                                final email = _getSelectedEmail(emails);
                                if (email?.status == EmailStatus.unread) {
                                  emailNotifier.markAsRead(email!.id!);
                                }
                              });
                            },
                            onDeleteEmail: (email) => _deleteEmail(email, emailNotifier),
                            onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Sağ Panel - E-posta Detayı
                        Expanded(
                          flex: 6,
                          child: EmailDetailPanel(
                            email: selectedEmail,
                            onReply: _replyToEmail,
                            onForward: _forwardEmail,
                            onDelete: (email) => _deleteEmail(email, emailNotifier),
                            onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier),
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
  Widget _buildMobileLayout(
    dynamic currentUser,
    List<Email> emails,
    EmailNotifier emailNotifier,
    EdgeInsets padding,
  ) {
    final filteredEmails = _getFilteredEmails(emails);
    final unreadCount = emails.where((e) => e.isUnread).length;

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
                totalEmails: emails.length,
                unreadEmails: unreadCount,
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
                      onComposeEmail: () => _showComposeEmailDialog(emailNotifier),
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
                        emails: filteredEmails,
                        selectedIndex: _selectedEmailIndex,
                        onEmailSelected: (index) {
                          setState(() {
                            _selectedEmailIndex = index;
                            final email = _getSelectedEmail(emails);
                            if (email?.status == EmailStatus.unread) {
                              emailNotifier.markAsRead(email!.id!);
                            }
                          });
                          // Mobilde e-posta detayına git
                          // TODO: Navigate to email detail screen
                        },
                        onDeleteEmail: (email) => _deleteEmail(email, emailNotifier),
                        onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier),
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

  void _markAsImportant(Email email, EmailNotifier emailNotifier) {
    if (email.id == null) return;
    final isImportant = email.importance != EmailImportance.important;
    emailNotifier.toggleImportant(email.id!, isImportant);
  }

  void _deleteEmail(Email email, EmailNotifier emailNotifier) {
    if (email.id == null) return;
    emailNotifier.deleteEmail(email.id!);
    setState(() {
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

  void _showComposeEmailDialog(EmailNotifier emailNotifier) {
    showDialog(
      context: context,
      builder: (context) => ComposeEmailDialog(
        onEmailSent: (email) async {
          try {
            await emailNotifier.sendEmail(
              accountId: email.accountId,
              toEmails: email.toEmails,
              subject: email.subject,
              plainText: email.plainText,
              htmlContent: email.htmlContent,
              importance: email.importance,
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('E-posta başarıyla gönderildi'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('E-posta gönderilirken hata oluştu: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
