import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/database/database_service.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'providers/theme_provider.dart';
import 'presentation/widgets/global_hotkeys.dart';
import 'services/notification_scheduler_service.dart';
import 'services/task_notification_service.dart';
import 'services/calendar_notification_service.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'repositories/task_repository.dart';
import 'models/task.dart';
import 'features/calendar/data/repositories/calendar_local_repository.dart';

// Global overlay context
BuildContext? _overlayContext;

/// Overlay context'i al (notification'lar için)
BuildContext? getOverlayContext() => _overlayContext;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows için database factory initialization
  if (defaultTargetPlatform == TargetPlatform.windows) {
    databaseFactory = databaseFactoryFfi;
  }

  // Supabase'i başlat
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: AppConfig.debugMode,
      authOptions: const FlutterAuthClientOptions(
        // Network hatalarını sessizce yönet
        autoRefreshToken: true,
      ),
    );

    // Auth state değişikliklerini dinle ve network hatalarını yönet
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        
        // Sadece önemli event'leri logla
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
          AppLogger.info('Auth event: $event', 'Supabase');
        }
      },
      onError: (error) {
        // Network hatalarını sessizce yönet (DNS lookup failures, connection errors, etc.)
        // Bu hatalar Supabase'in otomatik token yenileme mekanizmasından kaynaklanır
        // ve offline durumda normaldir
        final errorStr = error.toString();
        // Sadece network hataları değil, diğer önemli hataları logla
        if (!errorStr.contains('Failed host lookup') &&
            !errorStr.contains('SocketException') &&
            !errorStr.contains('AuthRetryableFetchException')) {
          AppLogger.warning('Auth state change error', 'Supabase', error);
        }
      },
    );
  } catch (e) {
    // Network hatası durumunda uygulama çalışmaya devam etsin
    AppLogger.warning('Supabase initialization error (non-critical)', 'Supabase', e);
  }

  // Veritabanını başlat
  try {
    await DatabaseService.instance.database;
    AppLogger.info('Database initialized successfully', 'Database');
  } catch (e) {
    AppLogger.error('Database initialization error', tag: 'Database', error: e);
  }

  // Görev bildirimleri için in-app sistem kullanılıyor (Windows native bildirimleri yok)
  AppLogger.info('✅ Task notification system ready (in-app mode)', 'Notifications');

  runApp(
    const ProviderScope(
      child: AIAssistantApp(),
    ),
  );
}

class AIAssistantApp extends ConsumerStatefulWidget {
  const AIAssistantApp({super.key});

  @override
  ConsumerState<AIAssistantApp> createState() => _AIAssistantAppState();
}

class _AIAssistantAppState extends ConsumerState<AIAssistantApp> {
  @override
  void initState() {
    super.initState();
    // Widget build edildikten sonra bildirim scheduler'ı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotificationScheduler();
    });
  }

  void _initializeNotificationScheduler() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.id != null) {
      try {
        // In-app bildirim scheduler'ı başlat
        final notificationSender = ref.read(notificationSenderProvider);
        final scheduler = NotificationSchedulerService();
        scheduler.start(
          notificationSender: notificationSender,
          userId: currentUser.id!,
        );
        AppLogger.info('Notification scheduler başlatıldı', 'Notifications');
        
        // Görev bildirimleri için mevcut görevleri yeniden zamanla
        try {
          final taskRepository = TaskRepository();
          final taskNotificationService = TaskNotificationService();
          final tasks = await taskRepository.getTasksByUserId(currentUser.id!);
          
          // Sadece bekleyen ve devam eden görevler için bildirim zamanla
          final pendingTasks = tasks.where((task) => 
            (task.status == TaskStatus.pending || task.status == TaskStatus.inProgress) &&
            task.dueDate != null &&
            task.dueDate!.isAfter(DateTime.now())
          ).toList();
          
          await taskNotificationService.rescheduleAllTaskNotifications(pendingTasks);
          AppLogger.info('${pendingTasks.length} görev için bildirimler zamanlandı', 'TaskNotifications');
        } catch (e) {
          AppLogger.warning('Görev bildirimleri zamanlanamadı', 'TaskNotifications', e);
        }
        
        // Takvim bildirimleri için mevcut event'leri yeniden zamanla
        try {
          final calendarLocalRepository = CalendarLocalRepository();
          final calendarNotificationService = CalendarNotificationService();
          final now = DateTime.now();
          final timeMax = now.add(const Duration(days: 30)); // Gelecek 30 gün içindeki event'ler
          
          final events = await calendarLocalRepository.getEvents(
            userId: currentUser.id!,
            timeMin: now,
            timeMax: timeMax,
          );
          
          await calendarNotificationService.rescheduleAllCalendarNotifications(events);
          AppLogger.info('${events.length} takvim event\'i için bildirimler zamanlandı', 'CalendarNotifications');
        } catch (e) {
          AppLogger.warning('Takvim bildirimleri zamanlanamadı', 'CalendarNotifications', e);
        }
      } catch (e) {
        AppLogger.warning('Notification scheduler başlatılamadı', 'Notifications', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTheme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Kullanıcı giriş yaptığında bildirim scheduler'ı başlat
    if (currentUser != null && currentUser.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final notificationSender = ref.read(notificationSenderProvider);
          final scheduler = NotificationSchedulerService();
          if (!scheduler.isRunning) {
            scheduler.start(
              notificationSender: notificationSender,
              userId: currentUser.id!,
            );
          }
        } catch (e) {
          // Sessizce devam et
        }
      });
    }

    return MaterialApp.router(
      title: 'AI Asistan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: userTheme.themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Navigator context'ini kaydet (child içindeki context overlay'e erişebilir)
        // Builder context'i değil, child widget context'ini kullanmalıyız
        return Builder(
          builder: (innerContext) {
            // Bu context overlay'e erişebilir
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _overlayContext = innerContext;
            });
            
            return GlobalHotkeys(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
