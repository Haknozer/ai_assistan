import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/email.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_exceptions.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/email_account_provider.dart';
import '../../../features/email/providers/email_provider.dart';
import '../../widgets/email/email_page_header.dart';
import '../../widgets/email/search_and_filter_bar.dart';
import '../../widgets/email/email_filter_section.dart';
import '../../widgets/email/email_list.dart';
import '../../widgets/email/email_detail_panel.dart';
import '../../widgets/email/compose_email_dialog.dart';
import '../../../models/email_account.dart';

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
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Email account'ları kontrol et
    final emailAccountsAsync = ref.watch(emailAccountsProvider(EmailAccountsParams(
      userId: currentUser.id,
    )));

    return emailAccountsAsync.when(
      data: (accounts) {
        // Tüm aktif email account'larını bul
        final activeAccounts = accounts
            .where((account) =>
                account.isActive &&
                account.id != null &&
                account.accessToken != null &&
                account.accessToken!.isNotEmpty)
            .toList();

        // Hiç aktif account yoksa hata göster
        if (activeAccounts.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('E-posta hesabı bağlı değil'),
                  const SizedBox(height: 8),
                  const Text(
                    'Lütfen ayarlardan Gmail veya Outlook hesabınızı bağlayın',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    child: const Text('Ayarlara Git'),
                  ),
                ],
              ),
            ),
          );
        }

        // Tüm account'lardan email'leri birleştir
        return _buildMultiAccountEmailView(
          context,
          currentUser,
          activeAccounts,
          padding,
          isDesktop,
        );
      },
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
              const Text('Email hesabı yüklenirken hata oluştu'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Birden fazla account'tan email'leri birleştirip göster
  Widget _buildMultiAccountEmailView(
    BuildContext context,
    dynamic currentUser,
    List<EmailAccount> accounts,
    EdgeInsets padding,
    bool isDesktop,
  ) {
    // Her account için email provider'ları oluştur ve izle
    final emailProviders = accounts.map((account) {
      final emailParams = EmailListParams(
        accountId: account.id,
        folder: _selectedFolder,
        accessToken: account.accessToken!,
      );
      return ref.watch(emailNotifierProvider(emailParams));
    }).toList();

    // Tüm provider'ların durumunu kontrol et
    final isLoading = emailProviders.any((provider) => provider.isLoading);
    final hasError = emailProviders.any((provider) => provider.hasError);

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Tüm email'leri birleştir (hata olsa bile başarılı olanları göster)
    final allEmails = <Email>[];
    String? firstErrorMessage;

    for (final emailProvider in emailProviders) {
      // Provider'dan email'leri al (data varsa)
      final emails = emailProvider.value;
      if (emails != null) {
        allEmails.addAll(emails);
      }

      // Hata varsa logla ama devam et
      if (emailProvider.hasError) {
        emailProvider.whenOrNull(
          error: (error, stack) {
            if (firstErrorMessage == null) {
              if (error is ApiException) {
                firstErrorMessage = error.message;
              } else {
                firstErrorMessage = error.toString();
              }
            }
            return null;
          },
        );
      }
    }

    // Hata varsa ama email'ler de varsa, email'leri göster ama uyarı ver
    if (hasError && allEmails.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  firstErrorMessage ?? 'E-posta yüklenirken hata oluştu',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Tüm provider'ları yenile
                    for (final account in accounts) {
                      final emailParams = EmailListParams(
                        accountId: account.id,
                        folder: _selectedFolder,
                        accessToken: account.accessToken!,
                      );
                      ref.read(emailNotifierProvider(emailParams).notifier).refresh();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tarihe göre sırala (en yeni üstte)
    allEmails.sort((a, b) {
      final dateA = a.receivedDate ?? a.sentDate ?? DateTime(1970);
      final dateB = b.receivedDate ?? b.sentDate ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    // İlk account'u primary olarak kullan (UI için)
    final primaryAccount = accounts.first;

    // Email notifier'ı primary account için oluştur (işlemler için)
    final emailParams = EmailListParams(
      accountId: primaryAccount.id,
      folder: _selectedFolder,
      accessToken: primaryAccount.accessToken!,
    );
    final emailNotifier = ref.read(emailNotifierProvider(emailParams).notifier);

    // Account ID -> Provider mapping oluştur
    final accountProviders = <int, EmailProvider>{};
    for (final account in accounts) {
      if (account.id != null) {
        accountProviders[account.id!] = account.provider;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(
        currentUser,
        allEmails,
        emailNotifier,
        emailParams,
        padding,
        isDesktop,
        primaryAccount,
        accountProviders,
      ),
    );
  }

  Widget _buildResponsiveLayout(
    dynamic currentUser,
    List<Email> emails,
    EmailNotifier emailNotifier,
    EmailListParams emailParams,
    EdgeInsets padding,
    bool isDesktop,
    EmailAccount account,
    Map<int, EmailProvider> accountProviders,
  ) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, emails, emailNotifier, emailParams, padding, account, accountProviders);
    } else {
      return _buildMobileLayout(currentUser, emails, emailNotifier, emailParams, padding, account, accountProviders);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(
    dynamic currentUser,
    List<Email> emails,
    EmailNotifier emailNotifier,
    EmailListParams emailParams,
    EdgeInsets padding,
    EmailAccount account,
    Map<int, EmailProvider> accountProviders,
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
                            provider: account.provider,
                            accountProviders: accountProviders,
                            onEmailSelected: (index) {
                              setState(() {
                                _selectedEmailIndex = index;
                                final email = _getSelectedEmail(emails);
                                if (email?.status == EmailStatus.unread && email?.messageId != null) {
                                  // Access token'ı email params'tan al
                                  emailNotifier.markAsRead(
                                    email!.messageId!,
                                    accessToken: emailParams.accessToken,
                                  );
                                }
                              });
                            },
                            onDeleteEmail: (email) => _deleteEmail(email, emailNotifier, emailParams),
                            onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier, emailParams),
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
                            onDelete: (email) => _deleteEmail(email, emailNotifier, emailParams),
                            onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier, emailParams),
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
    EmailListParams emailParams,
    EdgeInsets padding,
    EmailAccount account,
    Map<int, EmailProvider> accountProviders,
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
                        provider: account.provider,
                        accountProviders: accountProviders,
                        onEmailSelected: (index) {
                          setState(() {
                            _selectedEmailIndex = index;
                            final email = _getSelectedEmail(emails);
                            if (email?.status == EmailStatus.unread && email?.messageId != null) {
                              emailNotifier.markAsRead(
                                email!.messageId!,
                                accessToken: emailParams.accessToken,
                              );
                            }
                          });
                          // Mobilde e-posta detayına git
                          // TODO: Navigate to email detail screen
                        },
                        onDeleteEmail: (email) => _deleteEmail(email, emailNotifier, emailParams),
                        onMarkAsImportant: (email) => _markAsImportant(email, emailNotifier, emailParams),
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

  void _markAsImportant(Email email, EmailNotifier emailNotifier, EmailListParams emailParams) {
    // Gmail API messageId kullanır
    if (email.messageId == null) return;
    final isImportant = email.importance != EmailImportance.important;
    final emailId = int.tryParse(email.messageId!) ?? 0;
    if (emailId == 0) return;
    emailNotifier.toggleImportant(emailId, isImportant, accessToken: emailParams.accessToken);
  }

  void _deleteEmail(Email email, EmailNotifier emailNotifier, EmailListParams emailParams) {
    // Gmail API messageId kullanır
    if (email.messageId == null) return;
    final emailId = int.tryParse(email.messageId!) ?? 0;
    if (emailId == 0) return;
    emailNotifier.deleteEmail(emailId, accessToken: emailParams.accessToken);
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
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('E-posta başarıyla gönderildi'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('E-posta gönderilirken hata oluştu: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
