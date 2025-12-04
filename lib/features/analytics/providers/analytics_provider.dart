import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_analytics.dart';

/// Stat cards provider
final statCardsProvider = Provider((ref) {
  return MockAnalytics.statCards;
});

/// Weekly tasks provider
final weeklyTasksProvider = Provider<Map<String, int>>((ref) {
  return MockAnalytics.weeklyTasks;
});

/// Email distribution provider
final emailDistributionProvider = Provider<Map<String, int>>((ref) {
  return MockAnalytics.emailDistribution;
});

/// Monthly meetings provider
final monthlyMeetingsProvider = Provider<Map<String, int>>((ref) {
  return MockAnalytics.monthlyMeetings;
});

/// Priority tasks provider
final priorityTasksProvider = Provider<Map<String, int>>((ref) {
  return MockAnalytics.priorityTasks;
});

