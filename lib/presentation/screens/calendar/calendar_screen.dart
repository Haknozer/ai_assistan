import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/calendar_event.dart';
import '../../../utils/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/layout/side_menu.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../features/calendar/providers/calendar_provider.dart';
import '../../../models/calendar_account.dart';
import '../../../core/api/api_exceptions.dart';
import '../../widgets/calendar/calendar_page_header.dart';
import '../../widgets/calendar/month_selector.dart';
import '../../widgets/calendar/calendar_grid.dart';
import '../../widgets/calendar/events_list.dart';
import '../../widgets/calendar/add_event_dialog.dart';
import '../../widgets/calendar/event_notification_overlay.dart';

/// Combined events provider parametreleri
class _CombinedEventsParams {
  final DateTime timeMin;
  final DateTime timeMax;
  final String? googleToken;
  final String? outlookToken;
  final int userId;

  _CombinedEventsParams({
    required this.timeMin,
    required this.timeMax,
    required this.googleToken,
    required this.outlookToken,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CombinedEventsParams &&
        other.timeMin == timeMin &&
        other.timeMax == timeMax &&
        other.googleToken == googleToken &&
        other.outlookToken == outlookToken &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(timeMin, timeMax, googleToken, outlookToken, userId);
  }
}

/// Combined events provider (widget dışında tanımlı - sürekli yeniden oluşturulmasını önler)
final _combinedEventsProvider = FutureProvider.autoDispose.family<List<CalendarEvent>, _CombinedEventsParams>((ref, params) async {
  ref.keepAlive(); // Provider'ı keep alive yap (sürekli dispose olmasını önle)
  final calendarRepo = ref.watch(calendarRepositoryProvider);
  return await calendarRepo.getAllCombinedEvents(
    calendarId: 'primary',
    timeMin: params.timeMin,
    timeMax: params.timeMax,
    googleAccessToken: params.googleToken,
    outlookAccessToken: params.outlookToken,
    userId: params.userId,
  );
});

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
  

  @override
  void initState() {
    super.initState();
  }

  /// Seçili gün veya ay etkinliklerini döndürür
  List<CalendarEvent> _getDisplayedEvents(List<CalendarEvent> allEvents) {
    if (_selectedDay != null) {
      return allEvents.where((event) {
        final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
        return eventDate == selectedDate;
      }).toList();
    }
    return allEvents.where((event) {
      return event.startTime.year == _currentMonth.year && event.startTime.month == _currentMonth.month;
    }).toList();
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

    // Calendar account'ları kontrol et
    final calendarAccountsAsync = ref.watch(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser.id,
    )));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: calendarAccountsAsync.when(
        data: (accounts) {
          // Google Calendar account'u bul
          CalendarAccount? googleAccount;
          try {
            googleAccount = accounts.firstWhere(
              (account) => account.provider == CalendarProvider.google && account.isActive,
            );
          } catch (e) {
            googleAccount = null;
          }

          // Outlook Calendar account'u bul
          CalendarAccount? outlookAccount;
          try {
            outlookAccount = accounts.firstWhere(
              (account) => account.provider == CalendarProvider.outlook && account.isActive,
            );
          } catch (e) {
            outlookAccount = null;
          }

          return _buildResponsiveLayout(
            currentUser,
            padding,
            isDesktop,
            googleAccount: googleAccount,
            outlookAccount: outlookAccount,
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) {
          // Hata olsa bile ekranı göster (sadece local event'lerle)
          return _buildResponsiveLayout(
            currentUser,
            padding,
            isDesktop,
            googleAccount: null,
            outlookAccount: null,
          );
        },
      ),
    );
  }

  Widget _buildResponsiveLayout(
    dynamic currentUser,
    EdgeInsets padding,
    bool isDesktop, {
    CalendarAccount? googleAccount,
    CalendarAccount? outlookAccount,
  }) {
    if (isDesktop) {
      return _buildDesktopLayout(currentUser, padding, googleAccount: googleAccount, outlookAccount: outlookAccount);
    } else {
      return _buildMobileLayout(currentUser, padding, googleAccount: googleAccount, outlookAccount: outlookAccount);
    }
  }

  /// Desktop Layout - Sol menü + içerik
  Widget _buildDesktopLayout(
    dynamic currentUser,
    EdgeInsets padding, {
    CalendarAccount? googleAccount,
    CalendarAccount? outlookAccount,
  }) {
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
                    child: _buildCalendarView(
                      isDesktop: true,
                      googleAccount: googleAccount,
                      outlookAccount: outlookAccount,
                      currentUser: currentUser,
                    ),
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
  Widget _buildMobileLayout(
    dynamic currentUser,
    EdgeInsets padding, {
    CalendarAccount? googleAccount,
    CalendarAccount? outlookAccount,
  }) {
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
                child: _buildCalendarView(
                  isDesktop: false,
                  googleAccount: googleAccount,
                  outlookAccount: outlookAccount,
                  currentUser: currentUser,
                ),
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

  Widget _buildCalendarView({
    required bool isDesktop,
    CalendarAccount? googleAccount,
    CalendarAccount? outlookAccount,
    required dynamic currentUser,
  }) {
    // Hem Google hem Outlook Calendar event'lerini çek ve birleştir
    final timeMin = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final timeMax = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);

    final googleToken = googleAccount?.accessToken;
    final outlookToken = outlookAccount?.accessToken;
    
    // Eğer en az bir calendar bağlıysa event'leri çek
    if ((googleToken != null && googleToken.isNotEmpty) || (outlookToken != null && outlookToken.isNotEmpty)) {
      // Provider parametrelerini oluştur
      final params = _CombinedEventsParams(
        timeMin: timeMin,
        timeMax: timeMax,
        googleToken: googleToken,
        outlookToken: outlookToken,
        userId: currentUser.id,
      );

      final eventsAsyncValue = ref.watch(_combinedEventsProvider(params));

      return eventsAsyncValue.when(
        data: (events) {
          final displayedEvents = _getDisplayedEvents(events);

          return Column(
            children: [
              // Ay ve Yıl Seçimi
              MonthSelector(
                currentMonth: _currentMonth,
                onPreviousMonth: () {
                  setState(() {
                    _goToPreviousMonth();
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _goToNextMonth();
                  });
                },
                onTodayTap: () {
                  setState(() {
                    _goToToday();
                  });
                },
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
                              events: events,
                              onDayTap: _onDayTap,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Sağ Panel - Etkinlik Listesi
                          Expanded(
                            flex: 2,
                            child: EventsList(
                              title: _eventsListTitle,
                              events: displayedEvents,
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
                              events: events,
                              onDayTap: _onDayTap,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Etkinlik Listesi
                          Expanded(
                            child: EventsList(
                              title: _eventsListTitle,
                              events: displayedEvents,
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
        },
        loading: () => Column(
          children: [
            MonthSelector(
              currentMonth: _currentMonth,
              onPreviousMonth: () {
                setState(() {
                  _goToPreviousMonth();
                });
              },
              onNextMonth: () {
                setState(() {
                  _goToNextMonth();
                });
              },
              onTodayTap: () {
                setState(() {
                  _goToToday();
                });
              },
            ),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) {
          // Hata durumunda boş liste göster (local event'ler varsa onları göster)
          debugPrint('❌ Calendar Screen - Event yükleme hatası: $error');
          debugPrint('  Stack: $stack');
          
          // Hata olsa bile local event'leri göster
          return Column(
            children: [
              MonthSelector(
                currentMonth: _currentMonth,
                onPreviousMonth: () {
                  setState(() {
                    _goToPreviousMonth();
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _goToNextMonth();
                  });
                },
                onTodayTap: () {
                  setState(() {
                    _goToToday();
                  });
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Event\'ler yüklenemedi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString().length > 100 
                          ? '${error.toString().substring(0, 100)}...'
                          : error.toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Provider'ı invalidate et ve yeniden çalıştır
                          final refreshParams = _CombinedEventsParams(
                            timeMin: timeMin,
                            timeMax: timeMax,
                            googleToken: googleToken,
                            outlookToken: outlookToken,
                            userId: currentUser.id,
                          );
                          ref.invalidate(_combinedEventsProvider(refreshParams));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Google Calendar bağlı değil, sadece local event'ler (şimdilik boş)
      final allEvents = <CalendarEvent>[];
      final displayedEvents = _getDisplayedEvents(allEvents);

      return Column(
        children: [
          MonthSelector(
            currentMonth: _currentMonth,
            onPreviousMonth: () {
              setState(() {
                _goToPreviousMonth();
              });
            },
            onNextMonth: () {
              setState(() {
                _goToNextMonth();
              });
            },
            onTodayTap: () {
              setState(() {
                _goToToday();
              });
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CalendarGrid(
                          currentMonth: _currentMonth,
                          events: allEvents,
                          onDayTap: _onDayTap,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: EventsList(
                          title: _eventsListTitle,
                          events: displayedEvents,
                          onEventTap: (event) {},
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: CalendarGrid(
                          currentMonth: _currentMonth,
                          events: allEvents,
                          onDayTap: _onDayTap,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: EventsList(
                          title: _eventsListTitle,
                          events: displayedEvents,
                          onEventTap: (event) {},
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }
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
        context.go('/ai-assistant');
        break;
      case 7:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komut Paleti geliştiriliyor...')),
        );
        break;
      case 8:
        context.go('/settings');
        break;
    }
  }

  void _handleProfileTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sayfasına yönlendiriliyor...')),
    );
  }

  void _showAddEventDialog() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Google Calendar account'u kontrol et
    final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
      userId: currentUser.id,
    )));

    calendarAccountsAsync.whenData((accounts) {
      // Google Calendar account'u bul
      CalendarAccount? googleAccount;
      try {
        googleAccount = accounts.firstWhere(
          (account) => account.provider == CalendarProvider.google && account.isActive,
        );
      } catch (e) {
        googleAccount = null;
      }

      // Outlook Calendar account'u bul
      CalendarAccount? outlookAccount;
      try {
        outlookAccount = accounts.firstWhere(
          (account) => account.provider == CalendarProvider.outlook && account.isActive,
        );
      } catch (e) {
        outlookAccount = null;
      }

      // Önce Google, yoksa Outlook kullan
      final activeAccount = googleAccount ?? outlookAccount;
      final provider = googleAccount != null ? CalendarProvider.google : (outlookAccount != null ? CalendarProvider.outlook : null);
      final providerName = googleAccount != null ? 'Google Calendar' : (outlookAccount != null ? 'Outlook Calendar' : null);

      showDialog(
        context: context,
        builder: (dialogContext) => AddEventDialog(
          onEventAdded: (event) async {
            // Dialog'u kapat
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            
            // Calendar'a ekle (Google veya Outlook)
            if (activeAccount != null && activeAccount.accessToken != null && activeAccount.accessToken!.isNotEmpty && provider != null) {
              try {
                final eventParams = EventListParams(
                  calendarId: 'primary',
                  accessToken: activeAccount.accessToken,
                  provider: provider,
                  userId: currentUser.id,
                );
                final calendarNotifier = ref.read(calendarNotifierProvider(eventParams).notifier);
                
                final createdEvent = await calendarNotifier.createEvent(
                  title: event.title,
                  startTime: event.startTime,
                  endTime: event.endTime,
                  description: event.description,
                  location: event.location,
                  eventType: event.eventType,
                );
                
                if (mounted) {
                  EventNotificationOverlay.showEventAddedNotification(context, createdEvent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Event $providerName\'a eklendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Event listesini yenile - state'i yenile, provider otomatik olarak yeniden çalışacak
                  setState(() {
                    // State değiştiğinde provider yeniden çalışacak
                  });
                }
              } catch (e) {
                if (mounted) {
                  String errorMessage = 'Event eklenirken hata oluştu';
                  if (e is ValidationException) {
                    errorMessage = 'Event oluşturma hatası: ${e.message}';
                  } else if (e is ApiException) {
                    errorMessage = 'API hatası: ${e.message}';
                  } else {
                    errorMessage = 'Beklenmeyen hata: ${e.toString()}';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
                debugPrint('createEvent hatası: $e');
              }
            } else {
              // Sadece local'e ekle (Calendar bağlı değil)
              if (mounted) {
                EventNotificationOverlay.showEventAddedNotification(context, event);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calendar bağlı değil. Event sadece local\'e kaydedildi.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
        ),
      );
    });
  }
}
