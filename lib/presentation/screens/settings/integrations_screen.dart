import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/layout/side_menu.dart';
import '../../widgets/settings/settings_page_header.dart';
import '../../widgets/settings/integrations_category_card.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/responsive_utils.dart';
import 'data/integrations_data.dart';

/// Entegrasyonlar Ekranı - Tüm servisleri bağlama
class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  final int _selectedMenuIndex = 8; // Settings indeksi
  String? _selectedCategory; // Seçili kategori

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
              child: _buildIntegrationsContent(),
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
        title: const Text('Entegrasyonlar'),
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
          child: _buildIntegrationsContent(),
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

  Widget _buildIntegrationsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SettingsPageHeader(
              isDesktop: ResponsiveUtils.isDesktop(context),
            ),
          ),

          // Kategoriler
          ...IntegrationsData.allIntegrations.entries.map((entry) {
            return IntegrationsCategoryCard(
              category: entry.key,
              integrations: entry.value,
              selectedCategory: _selectedCategory,
              onCategoryTap: _handleCategoryTap,
              onIntegrationTap: _showIntegrationDialog,
            );
          }).toList(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleCategoryTap(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
  }

  void _showIntegrationDialog(String integrationName, bool isConnected) {
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
                SnackBar(content: Text('$integrationName ${isConnected ? "ayrıldı" : "bağlandı"}')),
              );
            },
            child: Text(isConnected ? 'Ayır' : 'Bağlan'),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(int index) {
    if (index == 8) {
      // Settings ekranına dön
      context.go('/settings');
      return;
    }

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
    context.go('/settings');
  }
}
