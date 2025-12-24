import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/side_menu.dart';
import '../../widgets/settings/settings_page_header.dart';
import '../../widgets/settings/settings_category_buttons.dart';
import '../../widgets/settings/integration_card.dart';
import '../../widgets/settings/notifications_card.dart';
import '../../widgets/settings/appearance_card.dart';
import '../../widgets/settings/productivity_card.dart';
import '../../widgets/settings/privacy_card.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_setting_provider.dart';
import '../../../models/user_setting.dart';
import '../../../providers/email_account_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../services/gmail_oauth_service.dart';
import '../../../services/outlook_oauth_service.dart';
import '../../../services/google_calendar_oauth_service.dart';
import '../../../services/outlook_calendar_oauth_service.dart';
import '../../../services/backend_email_service.dart';
import '../../../models/email_account.dart';
import '../../../models/calendar_account.dart';
import '../../../core/config/app_config.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../utils/responsive_utils.dart';
import 'data/settings_data.dart';
import '../../widgets/command_palette/command_palette_dialog.dart';
import '../../../core/router/app_router.dart';

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

    // Ayarlar ekranı açıldığında mevcut kullanıcının ayarlarını da yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && currentUser.id != null) {
        ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);
        
        // Bildirim ayarlarını provider'dan yükle
        final notificationSettings = ref.read(notificationSettingsProvider);
        if (notificationSettings.isNotEmpty) {
          // Provider'dan gelen ayarları state'e aktar
          setState(() {
            _notificationStates = {
              'Görev hatırlatıcıları ve son tarih uyarıları': notificationSettings['task_reminders'] ?? true,
              'Yaklaşan toplantılar için hatırlatmalar': notificationSettings['calendar_reminders'] ?? true,
              'Önemli e-postalar için anında bildirim': notificationSettings['email_notifications'] ?? false,
            };
          });
        }
      }
    });
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

    // Calendar account'ları kontrol et
    final calendarAccountsAsync = ref.watch(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser?.id,
    )));

    final isGoogleCalendarConnected = calendarAccountsAsync.when(
      data: (accounts) => accounts.any((account) => account.provider == CalendarProvider.google),
      loading: () => false,
      error: (_, __) => false,
    );

    final isOutlookCalendarConnected = calendarAccountsAsync.when(
      data: (accounts) => accounts.any((account) => account.provider == CalendarProvider.outlook),
      loading: () => false,
      error: (_, __) => false,
    );

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

    // Entegrasyon verilerini güncelle
    final integrationsData = Map<String, List<Map<String, dynamic>>>.from(SettingsData.integrations);
    integrationsData['E-posta Entegrasyonları'] = [
      {'name': 'Gmail', 'connected': isGmailConnected},
      {'name': 'Outlook', 'connected': isOutlookConnected},
    ];
    integrationsData['Takvim Entegrasyonları'] = [
      {'name': 'Google Calendar', 'connected': isGoogleCalendarConnected},
      {'name': 'Outlook Calendar', 'connected': isOutlookCalendarConnected},
    ];
    integrationsData['İletişim'] = [
      {'name': 'WhatsApp', 'connected': isWhatsappConnected},
      {'name': 'Telegram', 'connected': isTelegramConnected},
      {'name': 'Slack', 'connected': false},
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
            const SizedBox(height: 16),
            const ProductivityCard(),
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
    if (integrationName == 'WhatsApp') {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || currentUser.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce giriş yapmalısınız')),
        );
        return;
      }

      if (isConnected) {
        // WhatsApp zaten bağlıysa bağlantıyı kesme diyaloğu
        final shouldDisconnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('WhatsApp Bağlantısı'),
            content: const Text(
              'WhatsApp entegrasyonunu devre dışı bırakmak istiyor musunuz? Bu işlemden sonra WhatsApp üzerinden veri senkronu yapılmayacak.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bağlantıyı Kes'),
              ),
            ],
          ),
        );

        if (shouldDisconnect == true) {
          await ref
              .read(userSettingNotifierProvider.notifier)
              .updateBoolSetting(currentUser.id!, 'whatsapp_connected', false, category: SettingCategory.privacy);
          await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp bağlantısı devre dışı bırakıldı.'),
            ),
          );
        }
      } else {
        // WhatsApp bağlı değilse, kullanıcıdan onay alarak bağla
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('WhatsApp\'a Bağlan'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WhatsApp hesabınızı bu asistana bağlamak üzeresiniz.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '- Mesajlar Meta WhatsApp Business API üzerinden, uygulamanın kendi iş numarası ile gönderilir.\n'
                    '- Sizin kişisel WhatsApp hesabınız API\'ye bağlanmaz; sadece kime mesaj atmak istediğiniz numara kullanılır.\n'
                    '- Gizlilik ayarlarından "Bulut Senkronizasyonu" açık ise, mesaj geçmişiniz bulut ile senkronize edilebilir.\n'
                    '- Bulut senkron kapalı ise, veriler mümkün olduğunca sadece cihazınızda tutulur.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kabul ediyorum ve bağla'),
              ),
            ],
          ),
        );

        if (accepted == true) {
          await ref
              .read(userSettingNotifierProvider.notifier)
              .updateBoolSetting(currentUser.id!, 'whatsapp_connected', true, category: SettingCategory.privacy);
          await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp entegrasyonu aktifleştirildi.'),
            ),
          );
        }
      }
      return;
    }

    if (integrationName == 'Telegram') {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || currentUser.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce giriş yapmalısınız')),
        );
        return;
      }

      // Bot token kontrolü
      if (AppConfig.telegramBotToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Telegram bot token yapılandırılmamış. Lütfen run_windows.bat dosyasında TELEGRAM_BOT_TOKEN değerini ayarlayın.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      if (isConnected) {
        // Telegram zaten bağlıysa bağlantıyı kesme diyaloğu
        final shouldDisconnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Telegram Bağlantısı'),
            content: const Text(
              'Telegram entegrasyonunu devre dışı bırakmak istiyor musunuz? Bu işlemden sonra Telegram üzerinden mesaj senkronu yapılmayacak.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bağlantıyı Kes'),
              ),
            ],
          ),
        );

        if (shouldDisconnect == true) {
          await ref
              .read(userSettingNotifierProvider.notifier)
              .updateBoolSetting(currentUser.id!, 'telegram_connected', false, category: SettingCategory.privacy);
          await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram bağlantısı devre dışı bırakıldı.'),
            ),
          );
        }
      } else {
        // Telegram bağlı değilse, kullanıcıdan onay alarak bağla
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Telegram\'a Bağlan'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telegram bot entegrasyonunu aktifleştirmek üzeresiniz.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '- Telegram bot token\'ınız yapılandırılmış olmalıdır.\n'
                    '- Bot\'unuzun dahil olduğu gruplardan ve özel mesajlardan veri çekilecektir.\n'
                    '- Gizlilik ayarlarından "Bulut Senkronizasyonu" açık ise, mesaj geçmişiniz bulut ile senkronize edilebilir.\n'
                    '- Bulut senkron kapalı ise, veriler mümkün olduğunca sadece cihazınızda tutulur.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kabul ediyorum ve bağla'),
              ),
            ],
          ),
        );

        if (accepted == true) {
          await ref
              .read(userSettingNotifierProvider.notifier)
              .updateBoolSetting(currentUser.id!, 'telegram_connected', true, category: SettingCategory.privacy);
          await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram entegrasyonu aktifleştirildi.'),
            ),
          );
        }
      }
      return;
    }

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

    if (integrationName == 'Google Calendar') {
      if (isConnected) {
        // Google Calendar bağlıysa, bağlantıyı kes veya yeniden bağla seçenekleri sun
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Calendar Bağlantısı'),
            content: const Text(
              'Google Calendar hesabınız zaten bağlı. Ne yapmak istersiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _disconnectGoogleCalendar();
                },
                child: const Text('Bağlantıyı Kes'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connectGoogleCalendar();
                },
                child: const Text('Yeniden Bağlan'),
              ),
            ],
          ),
        );
      } else {
        // Google Calendar bağlı değilse, bağlan
        await _connectGoogleCalendar();
      }
      return;
    }

    if (integrationName == 'Outlook Calendar') {
      if (isConnected) {
        // Outlook Calendar bağlıysa, bağlantıyı kes veya yeniden bağla seçenekleri sun
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Outlook Calendar Bağlantısı'),
            content: const Text(
              'Outlook Calendar hesabınız zaten bağlı. Ne yapmak istersiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _disconnectOutlookCalendar();
                },
                child: const Text('Bağlantıyı Kes'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connectOutlookCalendar();
                },
                child: const Text('Yeniden Bağlan'),
              ),
            ],
          ),
        );
      } else {
        // Outlook Calendar bağlı değilse, bağlan
        await _connectOutlookCalendar();
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

    final accounts = emailAccountsAsync.value ?? [];
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

        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = 'Gmail bağlantısı kesilemedi';
        if (e is ApiException) {
          // Network hatası durumunda local database'den silindi mesajı göster
          if (e.message.contains('Failed host lookup') ||
              e.message.contains('Network error') ||
              e.message.contains('api.example.com')) {
            errorMessage = 'Gmail bağlantısı kesildi (local olarak)';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
              ),
            );
            // Listeyi yenile
            ref.invalidate(emailAccountsProvider(EmailAccountsParams(
              userId: currentUser.id,
            )));
            return;
          } else {
            errorMessage = e.message;
          }
        } else {
          errorMessage = 'Gmail bağlantısı kesilemedi: ${e.toString()}';
        }

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

      // Email account oluştur ve kaydet (local database)
      await emailAccountRepo.connectEmailAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: EmailProvider.gmail,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
        displayName: authResult.displayName,
      );

      // Backend'e email account'u bağla (background scheduler için)
      try {
        debugPrint('📧 Backend\'e Gmail account bağlama isteği gönderiliyor...');
        final backendEmailService = BackendEmailService();
        
        // Email account'u backend'e bağla
        // Bu sayede background scheduler otomatik olarak email'leri çekecek
        await backendEmailService.connectEmailAccount(
          provider: 'gmail',
          email: authResult.email,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          userId: currentUser.id,
        );

        debugPrint('✅ Gmail account backend\'e bağlandı');
        debugPrint('   Background scheduler otomatik olarak email\'leri çekecek (UI açık değilken bile)');
        
        // Başarı mesajı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gmail başarıyla bağlandı: ${authResult.email}\n'
                'Background scheduler otomatik olarak email\'leri çekecek',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (backendError) {
        debugPrint('⚠️ Backend Gmail account bağlama hatası: $backendError');
        // Backend hatası olsa bile OAuth başarılı olduğu için devam et
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gmail başarıyla bağlandı: ${authResult.email}\n'
                'Backend bağlantısı başarısız (${backendError.toString()})',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

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

    final accounts = emailAccountsAsync.value ?? [];
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

        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = 'Outlook bağlantısı kesilemedi';
        if (e is ApiException) {
          // Network hatası durumunda local database'den silindi mesajı göster
          if (e.message.contains('Failed host lookup') ||
              e.message.contains('Network error') ||
              e.message.contains('api.example.com')) {
            errorMessage = 'Outlook bağlantısı kesildi (local olarak)';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
              ),
            );
            // Listeyi yenile
            ref.invalidate(emailAccountsProvider(EmailAccountsParams(
              userId: currentUser.id,
            )));
            return;
          } else {
            errorMessage = e.message;
          }
        } else {
          errorMessage = 'Outlook bağlantısı kesilemedi: ${e.toString()}';
        }

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

      // Email account oluştur ve kaydet (local database)
      await emailAccountRepo.connectEmailAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: EmailProvider.outlook,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
        displayName: authResult.displayName,
      );

      // Backend'e email account'u bağla (background scheduler için)
      try {
        debugPrint('📧 Backend\'e Outlook account bağlama isteği gönderiliyor...');
        final backendEmailService = BackendEmailService();
        
        // Email account'u backend'e bağla
        // Bu sayede background scheduler otomatik olarak email'leri çekecek
        await backendEmailService.connectEmailAccount(
          provider: 'outlook',
          email: authResult.email,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          userId: currentUser.id,
        );

        debugPrint('✅ Outlook account backend\'e bağlandı');
        debugPrint('   Background scheduler otomatik olarak email\'leri çekecek (UI açık değilken bile)');
        
        // Başarı mesajı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Outlook başarıyla bağlandı: ${authResult.email}\n'
                'Background scheduler otomatik olarak email\'leri çekecek',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (backendError) {
        debugPrint('⚠️ Backend Outlook account bağlama hatası: $backendError');
        // Backend hatası olsa bile OAuth başarılı olduğu için devam et
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Outlook başarıyla bağlandı: ${authResult.email}\n'
                'Backend bağlantısı başarısız (${backendError.toString()})',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

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

  void _handleNotificationChanged(String title, bool value) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // State'i güncelle
    setState(() {
      _notificationStates[title] = value;
    });

    // Bildirim ayarını veritabanına kaydet
    // SettingsData'daki title'ı setting key'e çevir
    String settingKey = _getSettingKeyFromTitle(title);
    
    final notificationSettingsNotifier = ref.read(notificationSettingsProvider.notifier);
    await notificationSettingsNotifier.updateNotificationSetting(settingKey, value);

    // Ayarları yeniden yükle
    await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(currentUser.id!);

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title ${value ? "açık" : "kapalı"}')),
    );
  }

  /// Bildirim başlığından setting key'i al
  String _getSettingKeyFromTitle(String title) {
    // SettingsData.notificationCategories ile eşleştir
    final categories = SettingsData.notificationCategories;
    for (final entry in categories.entries) {
      if (entry.value == title) {
        // Kategori adından setting key oluştur
        switch (entry.key) {
          case 'Görev Bildirimi':
            return 'task_reminders';
          case 'Toplantı Bildirimi':
            return 'calendar_reminders';
          case 'E-posta Bildirimi':
            return 'email_notifications';
          case 'AI Öngörü Bildirimi':
            return 'ai_insights';
          default:
            return 'task_reminders';
        }
      }
    }
    return 'task_reminders';
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
        showCommandPaletteDialog(
          context,
          router: GoRouter.of(context),
          navigatorContext: rootNavigatorKey.currentContext,
        );
        break;
    }
  }

  Future<void> _disconnectGoogleCalendar() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Calendar account'ları al
    final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser.id,
    )));

    final accounts = calendarAccountsAsync.value ?? [];
    final googleCalendarAccount = accounts.firstWhere(
      (account) => account.provider == CalendarProvider.google,
      orElse: () => throw Exception('Google Calendar hesabı bulunamadı'),
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
      final calendarAccountRepo = ref.read(calendarAccountRepositoryProvider);
      await calendarAccountRepo.disconnectCalendarAccount(googleCalendarAccount.id!);

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar bağlantısı kesildi'),
            backgroundColor: Colors.orange,
          ),
        );

        // Listeyi yenile
        ref.invalidate(calendarAccountsProvider(CalendarAccountsParams(
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
            content: Text('Google Calendar bağlantısı kesilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectGoogleCalendar() async {
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

      // Google Calendar OAuth servisi
      final calendarOAuth = GoogleCalendarOAuthService(
        clientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
        clientSecret: AppConfig.googleClientSecret.isNotEmpty ? AppConfig.googleClientSecret : null,
      );
      final authResult = await calendarOAuth.connectCalendar();

      // Calendar account repository
      final calendarAccountRepo = ref.read(calendarAccountRepositoryProvider);

      // Calendar account oluştur ve kaydet
      await calendarAccountRepo.connectCalendarAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: CalendarProvider.google,
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
            content: Text('Google Calendar başarıyla bağlandı: ${authResult.email}'),
            backgroundColor: Colors.green,
          ),
        );

        // Listeyi yenile (state güncellemesi için)
        ref.invalidate(calendarAccountsProvider(CalendarAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = 'Google Calendar bağlantısı başarısız';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('invalid_client')) {
            errorMessage =
                'Client ID veya Client Secret yanlış. Lütfen Google Cloud Console\'daki değerleri kontrol edin.';
          } else if (errorStr.contains('timeout')) {
            errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
          } else {
            errorMessage = 'Google Calendar bağlantısı başarısız: ${e.toString()}';
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

  Future<void> _connectOutlookCalendar() async {
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

      // Outlook Calendar OAuth servisi
      final calendarOAuth = OutlookCalendarOAuthService(
        clientId: AppConfig.microsoftClientId.isNotEmpty ? AppConfig.microsoftClientId : null,
        clientSecret: AppConfig.microsoftClientSecret.isNotEmpty ? AppConfig.microsoftClientSecret : null,
      );
      final authResult = await calendarOAuth.connectCalendar();

      // Calendar account repository
      final calendarAccountRepo = ref.read(calendarAccountRepositoryProvider);

      // Calendar account oluştur ve kaydet
      await calendarAccountRepo.connectCalendarAccount(
        userId: currentUser.id!,
        emailAddress: authResult.email,
        provider: CalendarProvider.outlook,
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
            content: Text('Outlook Calendar başarıyla bağlandı: ${authResult.email}'),
            backgroundColor: Colors.green,
          ),
        );

        // Listeyi yenile (state güncellemesi için)
        ref.invalidate(calendarAccountsProvider(CalendarAccountsParams(
          userId: currentUser.id,
        )));
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context); // Loading dialog

        // Hata mesajını daha kullanıcı dostu hale getir
        String errorMessage = 'Outlook Calendar bağlantısı başarısız';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('invalid_client')) {
            errorMessage = 'Client ID veya Client Secret yanlış. Lütfen Azure Portal\'daki değerleri kontrol edin.';
          } else if (errorStr.contains('timeout')) {
            errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
          } else {
            errorMessage = 'Outlook Calendar bağlantısı başarısız: ${e.toString()}';
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

  Future<void> _disconnectOutlookCalendar() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || currentUser.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapmalısınız')),
      );
      return;
    }

    // Calendar account repository
    final calendarAccountRepo = ref.read(calendarAccountRepositoryProvider);

    // Outlook Calendar account'u bul
    final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser.id,
    )));

    final outlookAccount = calendarAccountsAsync.when(
      data: (accounts) => accounts.firstWhere(
        (account) => account.provider == CalendarProvider.outlook && account.isActive,
        orElse: () => throw Exception('Outlook Calendar hesabı bulunamadı'),
      ),
      loading: () => throw Exception('Hesaplar yükleniyor...'),
      error: (_, __) => throw Exception('Hesaplar yüklenemedi'),
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
      // Outlook Calendar bağlantısını kes
      await calendarAccountRepo.disconnectCalendarAccount(outlookAccount.id!);

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outlook Calendar bağlantısı kesildi'),
            backgroundColor: Colors.orange,
          ),
        );

        // Listeyi yenile
        ref.invalidate(calendarAccountsProvider(CalendarAccountsParams(
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
            content: Text('Outlook Calendar bağlantısı kesilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleProfileTap() {
    // Profile settings sayfasına yönlendirilebilir
  }
}
