import 'package:flutter/material.dart';

/// Uygulama içi bildirim overlay'i
class AppNotificationOverlay {
  /// Bildirim göster
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Navigator.of ile overlay'e eriş
    OverlayState? overlay;
    
    try {
      // Önce Navigator'dan al
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        overlay = navigator.overlay;
      }
    } catch (e) {
      // Navigator yoksa maybeOf kullan
      overlay = Overlay.maybeOf(context);
    }
    
    // Hala null ise rootOverlay dene
    overlay ??= Overlay.maybeOf(context, rootOverlay: true);
    
    if (overlay == null) {
      throw Exception('No Overlay widget found.');
    }
    
    _showWithOverlay(
      overlay: overlay,
      title: title,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      duration: duration,
      onTap: onTap,
    );
  }
  
  /// Overlay ile bildirim göster (internal)
  static void _showWithOverlay({
    required OverlayState overlay,
    required String title,
    required String message,
    required IconData icon,
    required Color? backgroundColor,
    required Duration duration,
    required VoidCallback? onTap,
  }) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        title: title,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        onTap: () {
          overlayEntry.remove();
          onTap?.call();
        },
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Otomatik kaldır
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Görev bildirimi
  static void showTaskNotification({
    required BuildContext context,
    required String taskTitle,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: 'Görev Hatırlatıcısı',
      message: '$taskTitle - $message',
      icon: Icons.task_alt,
      backgroundColor: Colors.blue,
      onTap: onTap,
    );
  }

  /// Toplantı bildirimi
  static void showCalendarNotification({
    required BuildContext context,
    required String eventTitle,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: 'Yaklaşan Toplantı',
      message: '$eventTitle - $message',
      icon: Icons.calendar_today,
      backgroundColor: Colors.green,
      onTap: onTap,
    );
  }

  /// E-posta bildirimi
  static void showEmailNotification({
    required BuildContext context,
    required String subject,
    required String sender,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: 'Yeni Önemli E-posta',
      message: '$sender: $subject',
      icon: Icons.email,
      backgroundColor: Colors.purple,
      onTap: onTap,
    );
  }

  /// AI önerisi bildirimi
  static void showAIInsight({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      icon: Icons.lightbulb,
      backgroundColor: Colors.amber,
      onTap: onTap,
    );
  }
}

class _NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.title,
    required this.message,
    required this.icon,
    this.backgroundColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

