import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_setting_provider.dart';
import '../../../models/user_setting.dart';

/// Gizlilik ve güvenlik kartı widget'ı
class PrivacyCard extends ConsumerWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(currentUserSettingsNotifierProvider);

    bool isCloudSyncEnabled = false;

    if (currentUser != null && settingsAsync.value != null) {
      try {
        final setting = settingsAsync.value!.firstWhere(
          (s) => s.settingKey == 'privacy_cloud_sync',
        );
        isCloudSyncEnabled = setting.getBoolValue();
      } catch (_) {
        isCloudSyncEnabled = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori Başlığı
            _buildHeader(context),
            const SizedBox(height: 16),

            // Şifreleme Bilgisi
            _buildEncryptionInfo(context),

            const SizedBox(height: 24),

            // Bulut Senkronizasyonu
            _buildCloudSyncSection(context, ref, currentUser != null, isCloudSyncEnabled),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İkon ve Başlık (aynı hizada)
        Row(
          children: [
            Icon(
              Icons.security_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Gizlilik & Güvenlik',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        // Küçük Başlık (altında)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Verilerinizi koruyun ve kontrol edin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Etkin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tüm verileriniz AES-256 şifreleme ile korunmaktadır.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncSection(
    BuildContext context,
    WidgetRef ref,
    bool hasUser,
    bool isCloudSyncEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bulut Senkronizasyonu',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                isCloudSyncEnabled
                    ? 'Cihazlar ve bulut arasında senkronizasyon AKTİF. İstediğiniz zaman kapatabilirsiniz.'
                    : 'Cihazlar arası ve bulut senkronizasyonu şu anda KAPALI. Verileriniz mümkün olduğunca sadece bu cihazda saklanır.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCloudSyncEnabled ? 'Bulut senkron açık' : 'Bulut senkron kapalı',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Switch(
              value: isCloudSyncEnabled,
              onChanged: !hasUser
                  ? null
                  : (value) async {
                      final user = ref.read(currentUserProvider);
                      if (user == null || user.id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Önce giriş yapmalısınız')),
                        );
                        return;
                      }

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Bulut Senkronizasyonu'),
                          content: Text(
                            value
                                ? 'Bulut senkronizasyonunu açarsanız; görevler, e-postalar ve WhatsApp mesajları gibi verileriniz bulutla senkronize edilebilir. Devam etmek istiyor musunuz?'
                                : 'Bulut senkronizasyonunu kapatırsanız yeni veriler mümkün olduğunca sadece bu cihazda saklanır. Devam etmek istiyor musunuz?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Vazgeç'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(value ? 'Evet, Aç' : 'Evet, Kapat'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      // Ayarı kaydet
                      await ref
                          .read(userSettingNotifierProvider.notifier)
                          .updateBoolSetting(user.id!, 'privacy_cloud_sync', value,
                              category: SettingCategory.privacy);

                      // Mevcut kullanıcı ayarlarını yenile
                      await ref.read(currentUserSettingsNotifierProvider.notifier).loadSettings(user.id!);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Bulut senkronizasyonu aktifleştirildi.'
                                : 'Bulut senkronizasyonu devre dışı bırakıldı.',
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ],
    );
  }
}