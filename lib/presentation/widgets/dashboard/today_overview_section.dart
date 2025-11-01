import 'package:flutter/material.dart';
import '../../../utils/responsive_utils.dart';
import 'today_tasks_card.dart';
import 'weather_card.dart';
import 'today_meetings_card.dart';

class TodayOverviewSection extends StatelessWidget {
  const TodayOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive height calculation
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = ResponsiveUtils.isDesktop(context)
        ? screenHeight * 0.6 // Desktop: 60% of screen height
        : screenHeight * 0.5; // Mobile: 50% of screen height

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          // Desktop: Side by side layout
          return SizedBox(
            height: containerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Today's Tasks (60%)
                Expanded(
                  flex: 6,
                  child: TodayTasksCard(height: containerHeight),
                ),
                const SizedBox(width: 16),
                // Right Side - Weather & Meetings (40%)
                const Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: WeatherCard(),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: TodayMeetingsCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Stacked layout
          return Column(
            children: [
              SizedBox(
                height: containerHeight,
                child: TodayTasksCard(height: containerHeight),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 200,
                child: WeatherCard(),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 250,
                child: TodayMeetingsCard(),
              ),
            ],
          );
        }
      },
    );
  }
}

