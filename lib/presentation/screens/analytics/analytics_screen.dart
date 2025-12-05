import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../features/analytics/analytics_feature.dart';
import '../../widgets/analytics/analytics_page_header.dart';
import '../../widgets/analytics/stats_grid.dart';
import '../../widgets/analytics/charts_section.dart';
import '../../widgets/analytics/weekly_summary_card.dart';

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
    return Column(
      children: [
        // Stats Cards
        StatsGrid(stats: MockAnalytics.statCards),

        const SizedBox(height: 24),

        // Charts Section - 2x2 Matrix
        const ChartsSection(),

        const SizedBox(height: 24),

        // Weekly Summary Card
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
    context.go('/settings');
  }

  void _downloadPDFReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF raporu hazırlanıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Gerçek PDF indirme işlemi
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
