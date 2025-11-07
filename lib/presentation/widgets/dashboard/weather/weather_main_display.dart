import 'package:flutter/material.dart';
import '../../../../models/weather.dart';
import 'weather_display_utils.dart';

/// Hava durumu ana görüntüleme widget'ı - Sol taraf (başlık, konum, derece)
class WeatherMainDisplay extends StatelessWidget {
  final Weather weather;
  final bool isSmall;

  const WeatherMainDisplay({
    super.key,
    required this.weather,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmall ? 40.0 : 56.0;
    final tempFontSize = isSmall ? 32.0 : 48.0;
    final titleFontSize = isSmall ? 16.0 : 20.0;
    final bodyFontSize = isSmall ? 12.0 : 14.0;
    final spacing = isSmall ? 8.0 : 12.0;

    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Text(
            'Hava Durumu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: spacing / 2),

          // Lokasyon - Timezone ve Ülke
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.white70,
                size: isSmall ? 14.0 : 16.0,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  WeatherDisplayUtils.getLocationText(weather),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: isSmall ? 11.0 : 13.0,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Icon + Derece + Açıklama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hava durumu ikonu
              Icon(
                WeatherDisplayUtils.getWeatherIcon(weather.icon),
                color: Colors.white,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        weather.formattedTemperature,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: tempFontSize,
                            ),
                      ),
                    ),
                    Text(
                      WeatherDisplayUtils.capitalizeFirst(weather.description),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: bodyFontSize,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

