import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/weather_provider.dart';
import 'weather/weather_main_display.dart';
import 'weather/weather_details_panel.dart';

/// Hava durumu kartı widget'ı - Dashboard için
class WeatherCard extends ConsumerStatefulWidget {
  const WeatherCard({super.key});

  @override
  ConsumerState<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends ConsumerState<WeatherCard> {
  @override
  void initState() {
    super.initState();
    // Uygulama açıldığında hava durumu isteği at
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider.notifier).loadCurrentLocationWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 280;

        // Responsive değerler
        final padding = isSmall ? 12.0 : 20.0;
        final spacing = isSmall ? 8.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withValues(alpha: 0.8),
                Colors.lightBlue.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: weatherState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : weatherState.error != null
                  ? _buildErrorState(context, isSmall)
                  : weatherState.weather == null
                      ? _buildEmptyState(context)
                      : _buildWeatherContent(context, weatherState.weather!, isSmall, spacing),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: isSmall ? 24.0 : 32.0,
          ),
          const SizedBox(height: 8),
          Text(
            'Hava durumu yüklenemedi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: isSmall ? 10.0 : 12.0,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'Veri yok',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
      ),
    );
  }

  Widget _buildWeatherContent(
    BuildContext context,
    dynamic weather,
    bool isSmall,
    double spacing,
  ) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol Taraf: Başlık, Konum, Derece
          WeatherMainDisplay(
            weather: weather,
            isSmall: isSmall,
          ),

          SizedBox(width: spacing),

          // Sağ Taraf: Nem ve Rüzgar (dikey)
          WeatherDetailsPanel(
            weather: weather,
            isSmall: isSmall,
          ),
        ],
      ),
    );
  }
}
