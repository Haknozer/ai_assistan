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
import '../../../models/email_account.dart';
import '../../../core/config/app_config.dart';
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

    // Gmail bağlı mı kontrol et
    final isGmailConnected = emailAccountsAsync.when(
      data: (accounts) => accounts.any((account) => account.provider == EmailProvider.gmail),
      loading: () => false,
      error: (_, __) => false,
    );

    // Entegrasyon verilerini güncelle
    final integrationsData = Map<String, List<Map<String, dynamic>>>.from(SettingsData.integrations);
    integrationsData['E-posta Entegrasyonları'] = [
      {'name': 'Gmail', 'connected': isGmailConnected},
      {'name': 'Outlook', 'connected': false},
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
    if (integrationName == 'Gmail' && !isConnected) {
      // Gmail OAuth bağlantısı
      await _connectGmail();
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
      if (context.mounted) {
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
      if (context.mounted) {
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
