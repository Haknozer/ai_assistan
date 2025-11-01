import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 280;

        // Responsive değerler
        final padding = isSmall ? 12.0 : 20.0;
        final iconSize = isSmall ? 40.0 : 56.0;
        final tempFontSize = isSmall ? 32.0 : 48.0;
        final titleFontSize = isSmall ? 16.0 : 20.0;
        final bodyFontSize = isSmall ? 12.0 : 14.0;
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
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol Taraf: Başlık, Konum, Derece
                Expanded(
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

                      // Lokasyon
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
                              'İstanbul, Türkiye',
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
                          Icon(
                            Icons.wb_sunny,
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
                                    '24°C',
                                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: tempFontSize,
                                        ),
                                  ),
                                ),
                                Text(
                                  'Parçalı Bulutlu',
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
                ),

                SizedBox(width: spacing),

                // Sağ Taraf: Nem ve Rüzgar (dikey)
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nem
                      Container(
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
                                  Icons.water_drop_outlined,
                                  color: Colors.white,
                                  size: isSmall ? 14.0 : 16.0,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nem',
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
                                '%65',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmall ? 13.0 : 15.0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Rüzgar
                      Container(
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
                                  Icons.air,
                                  color: Colors.white,
                                  size: isSmall ? 14.0 : 16.0,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Rüzgar',
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
                                '12 km/s',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmall ? 13.0 : 15.0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
