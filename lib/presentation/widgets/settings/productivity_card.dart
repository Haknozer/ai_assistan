import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_setting_provider.dart';
import '../../../models/user_setting.dart';
import '../../../core/config/app_config.dart';

/// Verimlilik skoru hedefi ayar kartı
class ProductivityCard extends ConsumerStatefulWidget {
  const ProductivityCard({super.key});

  @override
  ConsumerState<ProductivityCard> createState() => _ProductivityCardState();
}

class _ProductivityCardState extends ConsumerState<ProductivityCard> {
  double _currentValue = AppConfig.productivityTarget.toDouble();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settingsAsync = ref.watch(currentUserSettingsNotifierProvider);
    final user = ref.watch(currentUserProvider);

    if (user != null && settingsAsync.value != null) {
      final settings = settingsAsync.value!;
      final setting = settings.firstWhere(
        (s) => s.settingKey == 'productivity_target',
        orElse: () => UserSetting(
          userId: user.id!,
          settingKey: 'productivity_target',
          settingValue: AppConfig.productivityTarget.toString(),
          category: SettingCategory.general,
          updatedAt: DateTime.now(),
        ),
      );
      final value = setting.getIntValue();
      if (value > 0) {
        _currentValue = value.toDouble().clamp(50, 100);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Verimlilik Hedefi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Analytics',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Haftalık verimlilik skorunuz için hedef yüzdelik değeri belirleyin. '
            'Dashboard’daki “Verimlilik Skoru” kartı bu hedefe göre yeşil/kırmızı trend gösterecek.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Slider ve değer gösterimi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _currentValue,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label: '${_currentValue.round()}%',
                        onChanged: (value) {
                          setState(() {
                            _currentValue = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '50%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        Text(
                          'Hedef: ${_currentValue.round()}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        Text(
                          '100%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildSaveButton(context),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Önerilen: %80. Daha yüksek hedefler daha agresif, daha düşük hedefler daha esnek bir değerlendirme sağlar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDisabled = user == null || _isLoading;

    return SizedBox(
      width: 140,
      child: FilledButton.icon(
        onPressed: isDisabled ? null : () => _saveTarget(context, user),
        icon: _isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.check),
        label: Text(
          _isLoading ? 'Kaydediliyor...' : 'Kaydet',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        style: FilledButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTarget(BuildContext context, dynamic user) async {
    if (user == null || user.id == null) return;

    setState(() {
      _isLoading = true;
    });

    final notifier = ref.read(userSettingNotifierProvider.notifier);

    try {
      await notifier.updateSettingValue(
        user.id!,
        'productivity_target',
        _currentValue.round().toString(),
        category: SettingCategory.general,
      );
      await ref
          .read(currentUserSettingsNotifierProvider.notifier)
          .loadSettings(user.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Verimlilik hedefi ${_currentValue.round()}% olarak kaydedildi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hedef kaydedilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}


