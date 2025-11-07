import 'package:flutter/material.dart';
import '../../../../models/weather.dart';

/// Hava durumu detay paneli - Sağ taraf (nem, rüzgar)
class WeatherDetailsPanel extends StatelessWidget {
  final Weather weather;
  final bool isSmall;

  const WeatherDetailsPanel({
    super.key,
    required this.weather,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = isSmall ? 8.0 : 12.0;

    return Expanded(
      flex: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nem
          _buildDetailCard(
            context: context,
            icon: Icons.water_drop_outlined,
            label: 'Nem',
            value: weather.formattedHumidity,
            isSmall: isSmall,
          ),

          SizedBox(height: spacing),

          // Rüzgar
          _buildDetailCard(
            context: context,
            icon: Icons.air,
            label: 'Rüzgar',
            value: weather.formattedWindSpeed,
            isSmall: isSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isSmall,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 8.0 : 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isSmall ? 14.0 : 16.0,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: isSmall ? 9.0 : 10.0,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 13.0 : 15.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

