import 'package:flutter/material.dart';
import 'weekly_task_chart.dart';
import 'email_distribution_chart.dart';
import 'monthly_meeting_trend_chart.dart';
import 'priority_task_chart.dart';

/// Grafik bölümü widget'ı - Responsive chart layout
class ChartsSection extends StatelessWidget {
  const ChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoints for charts
        if (constraints.maxWidth > 1200) {
          // Desktop - 2x2 grid
          return Column(
            children: [
              // First row - Weekly Task Chart and Email Chart
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: const WeeklyTaskChart(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: const EmailDistributionChart(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Second row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: const MonthlyMeetingTrendChart(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: const PriorityTaskChart(),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else if (constraints.maxWidth > 600) {
          // Tablet - 1x2 grid (vertical)
          return Column(
            children: [
              const WeeklyTaskChart(),
              const SizedBox(height: 16),
              const EmailDistributionChart(),
              const SizedBox(height: 16),
              const MonthlyMeetingTrendChart(),
              const SizedBox(height: 16),
              const PriorityTaskChart(),
            ],
          );
        } else {
          // Mobile - Single column
          return Column(
            children: [
              const WeeklyTaskChart(),
              const SizedBox(height: 16),
              const EmailDistributionChart(),
              const SizedBox(height: 16),
              const MonthlyMeetingTrendChart(),
              const SizedBox(height: 16),
              const PriorityTaskChart(),
            ],
          );
        }
      },
    );
  }
}

