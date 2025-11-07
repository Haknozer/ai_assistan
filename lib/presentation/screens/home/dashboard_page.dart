import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../utils/responsive_utils.dart';
import '../../widgets/home/stats_cards.dart';
import '../../widgets/dashboard/welcome_header.dart';
import '../../widgets/dashboard/today_overview_section.dart';
import '../../widgets/dashboard/task_completion_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
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
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Responsive padding
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              WelcomeHeader(userName: currentUser.name),
              const SizedBox(height: 24),
              // Stats Cards Row
              const StatsCards(),
              const SizedBox(height: 24),
              // Today's Overview Section
              const TodayOverviewSection(),
              const SizedBox(height: 24),
              // Task Completion Card
              const TaskCompletionCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
