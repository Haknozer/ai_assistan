import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_setting_provider.dart';
import '../../../models/user_setting.dart';
import '../../../core/config/app_config.dart';
import '../../../features/analytics/analytics_feature.dart';
import '../../../features/analytics/providers/analytics_provider.dart';
import '../../widgets/command_palette/command_palette_dialog.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/analytics/analytics_page_header.dart';
import '../../widgets/analytics/stats_grid.dart';
import '../../widgets/analytics/charts_section.dart';
import '../../widgets/analytics/weekly_summary_card.dart';
import '../../../services/pdf_report_service.dart';

/// Analitik ekranı - Veri analizi ve raporlama
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final int _selectedMenuIndex = 5; // Analytics indeksi

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
              child: CustomScrollView(
                slivers: [
                  // Floating Header - kaybolan/görünen
                  SliverPersistentHeader(
                    pinned: false,
                    floating: true,
                    delegate: _SliverAppBarDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: AnalyticsPageHeader(
                            onDownloadPDF: _downloadPDFReport,
                            isDesktop: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  SliverToBoxAdapter(
                    child: _buildAnalyticsContent(),
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
        title: AnalyticsPageHeader(
          onDownloadPDF: _downloadPDFReport,
          isDesktop: false,
        ),
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
          child: SingleChildScrollView(
            child: _buildAnalyticsContent(),
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

  Widget _buildAnalyticsContent() {
    final statCardsAsync = ref.watch(statCardsProvider);

    return Column(
      children: [
        // Stats Cards
        statCardsAsync.when(
          data: (stats) => StatsGrid(stats: stats),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'İstatistikler yüklenirken bir hata oluştu: $e',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Charts Section - 2x2 Matrix
        const ChartsSection(),

        const SizedBox(height: 24),

        // Weekly Summary Card (şimdilik statik metin)
        const WeeklySummaryCard(),
      ],
    );
  }

  void _handleMenuTap(int index) {
    if (index == 5) return; // Zaten analytics'teyiz

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
      case 8:
        context.go('/settings');
        break;
    }
  }

  void _handleProfileTap() {
    context.go('/settings');
  }

  Future<void> _downloadPDFReport() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF oluşturmak için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Repository'den direkt verileri al (provider yerine)
      final analyticsRepo = ref.read(analyticsRepositoryProvider);

      // Kullanıcıya özel verimlilik hedefi (yoksa global default)
      final settings = ref.read(currentUserSettingsNotifierProvider);
      int productivityTarget = AppConfig.productivityTarget;
      if (settings.value != null && settings.value!.isNotEmpty) {
        final setting = settings.value!.firstWhere(
          (s) => s.settingKey == 'productivity_target',
          orElse: () => UserSetting(
            userId: currentUser.id!,
            settingKey: 'productivity_target',
            settingValue: AppConfig.productivityTarget.toString(),
            category: SettingCategory.general,
            updatedAt: DateTime.now(),
          ),
        );
        productivityTarget = setting.getIntValue();
        if (productivityTarget <= 0) {
          productivityTarget = AppConfig.productivityTarget;
        }
      }

      // Repository'den direkt verileri çek
      debugPrint('📊 PDF için veriler repository\'den çekiliyor...');
      final stats = await analyticsRepo.getStatCards(
        userId: currentUser.id!,
        productivityTarget: productivityTarget,
      );
      final weeklyTasks = await analyticsRepo.getWeeklyTasks(userId: currentUser.id!);
      final weeklyTasksDetailed = await analyticsRepo.getWeeklyTasksDetailed(userId: currentUser.id!);
      final emailDistribution = await analyticsRepo.getEmailDistribution(userId: currentUser.id!);
      final monthlyMeetings = await analyticsRepo.getMonthlyMeetings(userId: currentUser.id!);
      final priorityTasks = await analyticsRepo.getPriorityTasks(userId: currentUser.id!);

      // Debug: Stats listesini kontrol et
      debugPrint('📊 PDF oluşturuluyor - Stats sayısı: ${stats.length}');
      if (stats.isEmpty) {
        debugPrint('⚠️ Stats listesi boş!');
      } else {
        for (var i = 0; i < stats.length; i++) {
          debugPrint('  Stat $i: ${stats[i].title} - ${stats[i].mainValue}');
        }
      }

      // PDF oluştur
      final pdfService = PDFReportService();
      final pdfFile = await pdfService.generateAnalyticsPDF(
        stats: stats,
        weeklyTasks: weeklyTasks,
        weeklyTasksDetailed: weeklyTasksDetailed,
        emailDistribution: emailDistribution,
        monthlyMeetings: monthlyMeetings,
        priorityTasks: priorityTasks,
        userName: currentUser.name,
        userEmail: currentUser.email,
      );

      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);
      }

      if (pdfFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF oluşturulurken bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // PDF'i direkt aç (OneNote seçeneği gelmesin)
      if (mounted) {
        // PDF'i direkt aç - OneNote seçeneği gelmez, sadece PDF görüntüleyici açılır
        await OpenFile.open(pdfFile.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF raporu hazırlandı ve açıldı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Dialog'u kapat
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 120;

  @override
  double get maxExtent => 120;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
