import 'package:flutter/material.dart';
import '../../../models/task.dart';
import '../../screens/tasks/utils/task_utils.dart';
import '../../../core/theme/app_theme.dart';

/// Görev bildirimi overlay widget'ı
class TaskNotificationOverlay {
  /// Genel bildirim göster
  static void show({
    required BuildContext context,
    required Task task,
    required String message,
    TaskStatus? status,
  }) {
    final color = status != null ? TaskUtils.getStatusColor(status) : AppTheme.successColor;
    _showNotification(context, task, message, color);
  }

  /// Görev durumu güncelleme bildirimi göster
  static void showTaskUpdateNotification(
    BuildContext context,
    Task task,
    TaskStatus newStatus,
  ) {
    show(
      context: context,
      task: task,
      message: 'Projenizin durumu ${newStatus.displayName} olarak değiştirildi',
      status: newStatus,
    );
  }

  /// Görev ekleme bildirimi göster (eski metod - geriye uyumluluk için)
  static void showTaskAddedNotification(BuildContext context, Task task) {
    show(
      context: context,
      task: task,
      message: 'Projeniz başarıyla eklendi',
      status: null,
    );
  }

  static void _showNotification(
    BuildContext context,
    Task task,
    String message,
    Color color,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => overlayEntry.remove(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () => overlayEntry.remove());
  }
}
