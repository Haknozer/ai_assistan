import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/calendar_event.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import 'data/mock_events.dart';
import '../../widgets/calendar/calendar_page_header.dart';
import '../../widgets/calendar/month_selector.dart';
import '../../widgets/calendar/calendar_grid.dart';
import '../../widgets/calendar/events_list.dart';
import '../../widgets/calendar/add_event_dialog.dart';
import '../../widgets/calendar/event_notification_overlay.dart';

/// Takvim ekranı - Etkinlik planlama ve yönetimi
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final int _selectedMenuIndex = 3;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  late List<CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = List.from(MockEvents.events);
  }

  /// Seçili gün veya ay etkinliklerini döndürür
  List<CalendarEvent> get _displayedEvents {
    if (_selectedDay != null) {
      return MockEvents.getEventsForDay(_events, _selectedDay!);
    }
    return MockEvents.getEventsForMonth(_events, _currentMonth);
  }

  String get _eventsListTitle {
    if (_selectedDay != null) {
      return 'Seçili Gün Etkinlikleri';
    }
    return 'Aylık Etkinlikler';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildResponsiveLayout(currentUser, padding, isDesktop),
    );
  }

  Widget _buildResponsiveLayout(dynamic currentUser, EdgeInsets padding, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, padding);
    } else {
      return _buildMobileLayout(currentUser, padding);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(dynamic currentUser, EdgeInsets padding) {
    return Row(
      children: [
        // Sol Menü
        SizedBox(
          width: 280,
          child: SideMenu(
            userName: currentUser.name,
            userEmail: currentUser.email,
            selectedIndex: _selectedMenuIndex,
            onMenuTap: _handleMenuTap,
            onProfileTap: _handleProfileTap,
          ),
        ),
        // Ana İçerik Alanı
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sayfa Başlığı ve Etkinlik Ekle Butonu
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: CalendarPageHeader(
                      onAddEvent: _showAddEventDialog,
                      isDesktop: true,
                    ),
                  ),

                  // Takvim Görünümü
                  Expanded(
                    child: _buildCalendarView(isDesktop: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile Layout - AppBar + Drawer + içerik
  Widget _buildMobileLayout(dynamic currentUser, EdgeInsets padding) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Mobil AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.getBorderColor(context),
                    width: 1,
                  ),
                ),
              ),
              child: CalendarPageHeader(
                onAddEvent: _showAddEventDialog,
                isDesktop: false,
              ),
            ),

            // Mobil İçerik
            Expanded(
              child: Padding(
                padding: padding.copyWith(top: 16),
                child: _buildCalendarView(isDesktop: false),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: 280,
        child: SideMenu(
          userName: currentUser.name,
          userEmail: currentUser.email,
          selectedIndex: _selectedMenuIndex,
          onMenuTap: (index) {
            Navigator.pop(context);
            _handleMenuTap(index);
          },
          onProfileTap: () {
            Navigator.pop(context);
            _handleProfileTap();
          },
        ),
      ),
    );
  }

  Widget _buildCalendarView({required bool isDesktop}) {
    return Column(
      children: [
        // Ay ve Yıl Seçimi
        MonthSelector(
          currentMonth: _currentMonth,
          onPreviousMonth: _goToPreviousMonth,
          onNextMonth: _goToNextMonth,
          onTodayTap: _goToToday,
        ),
        const SizedBox(height: 20),

        // Takvim Grid ve Etkinlik Listesi
        Expanded(
          child: isDesktop
              ? Row(
                  children: [
                    // Sol Panel - Takvim Grid
                    Expanded(
                      flex: 3,
                      child: CalendarGrid(
                        currentMonth: _currentMonth,
                        events: _events,
                        onDayTap: _onDayTap,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Sağ Panel - Etkinlik Listesi
                    Expanded(
                      flex: 2,
                      child: EventsList(
                        title: _eventsListTitle,
                        events: _displayedEvents,
                        onEventTap: (event) {
                          // TODO: Göster etkinlik detayı
                        },
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Takvim Grid
                    Expanded(
                      child: CalendarGrid(
                        currentMonth: _currentMonth,
                        events: _events,
                        onDayTap: _onDayTap,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Etkinlik Listesi
                    Expanded(
                      child: EventsList(
                        title: _eventsListTitle,
                        events: _displayedEvents,
                        onEventTap: (event) {
                          // TODO: Göster etkinlik detayı
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDay = null;
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  void _handleMenuTap(int index) {
    if (index == 3) return; // Zaten takvim sayfasındayız

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/messages');
        break;
      case 2:
        context.go('/tasks');
        break;
      case 4:
        context.go('/email');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 6:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Asistan geliştiriliyor...')),
        );
        break;
      case 7:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onEventAdded: (event) {
          setState(() => _events.add(event));
          Navigator.pop(context);
          EventNotificationOverlay.showEventAddedNotification(context, event);
        },
      ),
    );
  }
}
