import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/side_menu.dart';
import '../../widgets/settings/settings_page_header.dart';
import '../../widgets/settings/settings_category_buttons.dart';
import '../../widgets/settings/integration_card.dart';
import '../../widgets/settings/notifications_card.dart';
import '../../widgets/settings/appearance_card.dart';
import '../../widgets/settings/privacy_card.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/email_account_provider.dart';
import '../../../services/gmail_oauth_service.dart';
import '../../../services/outlook_oauth_service.dart';
import '../../../models/email_account.dart';
import '../../../core/config/app_config.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../utils/responsive_utils.dart';
import 'data/settings_data.dart';

/// Ayarlar Ekranı - Entegrasyonlar, Bildirimler, Görünüm, Gizlilik
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final int _selectedMenuIndex = 8; // Settings indeksi
  String? _selectedCategory = 'Entegrasyonlar'; // Default seçili kategori

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Bildirim durumları
  late Map<String, bool> _notificationStates;

  @override
  void initState() {
    super.initState();
    _notificationStates = Map.from(SettingsData.defaultNotificationStates);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  // Sabit Başlık Alanı
                  const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: SettingsPageHeader(isDesktop: true),
                  ),
                  // Scroll Olacak İçerik Alanı
                  Expanded(
                    child: _buildScrollableContent(),
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
      appBar: AppBar(
        title: const Text('Ayarlar'),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: padding.copyWith(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sabit Başlık Alanı
              const Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: SettingsPageHeader(isDesktop: false),
              ),
              // Scroll Olacak İçerik Alanı
              Expanded(
                child: _buildScrollableContent(),
              ),
            ],
          ),
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

  Widget _buildScrollableContent() {
    final currentUser = ref.watch(currentUserProvider);

    // Email account'ları kontrol et (Gmail bağlantısı için)
    final emailAccountsAsync = ref.watch(emailAccountsProvider(EmailAccountsParams(
      userId: currentUser?.id,
    )));

    // Gmail ve Outlook bağlı mı kontrol et
    final isGmailConnected = emailAccountsAsync.when(
      data: (accounts) => accounts.any((account) => account.provider == EmailProvider.gmail),
      loading: () => false,
      error: (_, __) => false,
    );

    final isOutlookConnected = emailAccountsAsync.when(
      data: (accounts) => accounts.any((account) => account.provider == EmailProvider.outlook),
      loading: () => false,
      error: (_, __) => false,
    );

    // Entegrasyon verilerini güncelle
    final integrationsData = Map<String, List<Map<String, dynamic>>>.from(SettingsData.integrations);
    integrationsData['E-posta Entegrasyonları'] = [
      {'name': 'Gmail', 'connected': isGmailConnected},
      {'name': 'Outlook', 'connected': isOutlookConnected},
      {'name': 'Yahoo Mail', 'connected': false},
    ];

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Categories Card
          SettingsCategoryButtons(
            selectedCategory: _selectedCategory,
            onCategoryTap: _onCategoryTap,
          ),

          // Entegrasyonlar Section (genişletilmişse)
          if (_selectedCategory == 'Entegrasyonlar') ...[
            const SizedBox(height: 16),
            ...integrationsData.entries.map((entry) {
              return IntegrationCard(
                category: entry.key,
                integrations: entry.value,
                onIntegrationTap: _showIntegrationDialog,
              );
            }).toList(),
          ],

          // Bildirimler Section (genişletilmişse)
          if (_selectedCategory == 'Bildirimler') ...[
            const SizedBox(height: 16),
            NotificationsCard(
              notificationStates: _notificationStates,
              onNotificationChanged: _handleNotificationChanged,
            ),
          ],

          // Görünüm Section (genişletilmişse)
          if (_selectedCategory == 'Görünüm') ...[
            const SizedBox(height: 16),
            const AppearanceCard(),
          ],

          // Gizlilik Section (genişletilmişse)
          if (_selectedCategory == 'Gizlilik') ...[
            const SizedBox(height: 16),
            const PrivacyCard(),
          ],

          // Bottom padding
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _onCategoryTap(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });

    // Kategori değiştiğinde sayfanın en başına scroll et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showIntegrationDialog(String integrationName, bool isConnected) async {
    if (integrationName == 'Gmail') {
      if (isConnected) {
        // Gmail bağlıysa, bağlantıyı kes veya yeniden bağla seçenekleri sun
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gmail Bağlantısı'),
            content: const Text(
              'Gmail hesabınız zaten bağlı. Ne yapmak istersiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _disconnectGmail();
                },
                child: const Text('Bağlantıyı Kes'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connectGmail();
                },
                child: const Text('Yeniden Bağlan'),
              ),
            ],
          ),
        );
      } else {
        // Gmail bağlı değilse, bağlan
        await _connectGmail();
      }
      return;
    }

    if (integrationName == 'Outlook') {
      if (isConnected) {
        // Outlook bağlıysa, bağlantıyı kes veya yeniden bağla seçenekleri sun
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Outlook Bağlantısı'),
            content: const Text(
              'Outlook hesabınız zaten bağlı. Ne yapmak istersiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _disconnectOutlook();
                },
                child: const Text('Bağlantıyı Kes'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connectOutlook();
                },
                child: const Text('Yeniden Bağlan'),
              ),
            ],
          ),
        );
      } else {
        // Outlook bağlı değilse, bağlan
        await _connectOutlook();
      }
      return;
    }

    // Diğer entegrasyonlar için standart dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$integrationName ${isConnected ? "Ayır" : "Bağlan"}'),
        content: Text(
          '$integrationName ${isConnected ? "entegrasyonunu ayırmak istediğinizden emin misiniz?" : "entegrasyonu kurmak istediğinizden emin misiniz?"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$integrationName ${isConnected ? "bağlantısı kesildi" : "bağlandı"}',
                  ),
                ),
              );
            },
            child: Text(isConnected ? 'Bağlantıyı Kes' : 'Bağlan'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectGmail() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Email account'ları al
    final emailAccountsAsync = ref.read(emailAccountsProvider(EmailAccountsParams(
      userId: currentUser.id,
    )));

    final accounts = await emailAccountsAsync.value ?? [];
    final gmailAccount = accounts.firstWhere(
      (account) => account.provider == EmailProvider.gmail,
      orElse: () => throw Exception('Gmail hesabı bulunamadı'),
    );

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final emailAccountRepo = ref.read(emailAccountRepositoryProvider);
      await emailAccountRepo.disconnectEmailAccount(gmailAccount.id!);

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gmail bağlantısı kesildi'),
            backgroundColor: Colors.orange,
          ),
        );

        // Listeyi yenile
        ref.invalidate(emailAccountsProvider(EmailAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail bağlantısı kesilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectGmail() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Debug: Client ID ve Secret kontrolü
      debugPrint('Client ID: ${AppConfig.googleClientId}');
      debugPrint('Client Secret: ${AppConfig.googleClientSecret.isNotEmpty ? "***GİZLİ***" : "BOŞ"}');

      // Gmail OAuth servisi
      final gmailOAuth = GmailOAuthService(
        clientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
        clientSecret: AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null,
      );
      final authResult = await gmailOAuth.connectGmail();

      // Email account repository
      final emailAccountRepo = ref.read(emailAccountRepositoryProvider);

      // Email account oluştur ve kaydet
      await emailAccountRepo.connectEmailAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: EmailProvider.gmail,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
        displayName: authResult.displayName,
      );

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail başarıyla bağlandı: ${authResult.email}'),
            backgroundColor: Colors.green,
          ),
        );

        // Listeyi yenile (state güncellemesi için)
        ref.invalidate(emailAccountsProvider(EmailAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail bağlantısı başarısız: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectOutlook() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Email account'ları al
    final emailAccountsAsync = ref.read(emailAccountsProvider(EmailAccountsParams(
      userId: currentUser.id,
    )));

    final accounts = await emailAccountsAsync.value ?? [];
    final outlookAccount = accounts.firstWhere(
      (account) => account.provider == EmailProvider.outlook,
      orElse: () => throw Exception('Outlook hesabı bulunamadı'),
    );

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final emailAccountRepo = ref.read(emailAccountRepositoryProvider);
      await emailAccountRepo.disconnectEmailAccount(outlookAccount.id!);

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outlook bağlantısı kesildi'),
            backgroundColor: Colors.orange,
          ),
        );

        // Listeyi yenile
        ref.invalidate(emailAccountsProvider(EmailAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Outlook bağlantısı kesilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectOutlook() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Debug: Client ID ve Secret kontrolü
      debugPrint('Microsoft Client ID: ${AppConfig.microsoftClientId}');
      debugPrint('Microsoft Client Secret: ${AppConfig.microsoftClientSecret.isNotEmpty ? "***GİZLİ***" : "BOŞ"}');

      // Outlook OAuth servisi
      final outlookOAuth = OutlookOAuthService(
        clientId: AppConfig.microsoftClientId.isNotEmpty ? AppConfig.microsoftClientId : null,
        clientSecret: AppConfig.microsoftClientSecret.isNotEmpty ? AppConfig.microsoftClientSecret : null,
      );
      final authResult = await outlookOAuth.connectOutlook();

      // Email account repository
      final emailAccountRepo = ref.read(emailAccountRepositoryProvider);

      // Email account oluştur ve kaydet
      await emailAccountRepo.connectEmailAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: EmailProvider.outlook,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
        displayName: authResult.displayName,
      );

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Outlook başarıyla bağlandı: ${authResult.email}'),
            backgroundColor: Colors.green,
          ),
        );

        // Listeyi yenile (state güncellemesi için)
        ref.invalidate(emailAccountsProvider(EmailAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = 'Outlook bağlantısı başarısız';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('invalid_client')) {
            errorMessage = 'Client ID veya Client Secret yanlış. Lütfen Azure Portal\'daki değerleri kontrol edin.';
          } else if (errorStr.contains('timeout')) {
            errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
          } else {
            errorMessage = 'Outlook bağlantısı başarısız: ${e.toString()}';
          }
        }

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleNotificationChanged(String title, bool value) {
    setState(() {
      _notificationStates[title] = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title ${value ? "açık" : "kapalı"}')),
    );
  }

  void _handleMenuTap(int index) {
    if (index == 8) return; // Zaten settings'teyiz

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
      case 4:
        context.go('/email');
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
    }
  }

  void _handleProfileTap() {
    // Profile settings sayfasına yönlendirilebilir
  }
}
