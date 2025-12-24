import 'package:flutter/material.dart';
import '../../../models/task.dart';

/// Çöp kutusu widget'ı - Görevleri sürükleyerek silmek için
/// Sayfanın altında sabit, modern ve responsive tasarım
class TrashBinWidget extends StatefulWidget {
  final Function(Task) onTaskDropped;

  const TrashBinWidget({
    super.key,
    required this.onTaskDropped,
  });

  @override
  State<TrashBinWidget> createState() => _TrashBinWidgetState();
}

class _TrashBinWidgetState extends State<TrashBinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragStarted() {
    if (!_isDragging) {
      setState(() => _isDragging = true);
      _animationController.forward();
    }
  }

  void _onDragEnded() {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Scroll sırasında drag durumunu kontrol et
        return false;
      },
      child: DragTarget<Task>(
        onWillAcceptWithDetails: (details) {
          if (!_isDragging) _onDragStarted();
          return true;
        },
        onAcceptWithDetails: (details) {
          widget.onTaskDropped(details.data);
          _onDragEnded();
        },
        onLeave: (data) {
          _onDragEnded();
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: isHovering ? 1.05 : _scaleAnimation.value,
                child: Opacity(
                  opacity: isHovering ? 1.0 : _opacityAnimation.value,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? Colors.red.withValues(alpha: isDark ? 0.25 : 0.1)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border(
                        top: BorderSide(
                          color: isHovering
                              ? Colors.red
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          width: isHovering ? 2 : 1,
                        ),
                      ),
                      boxShadow: isHovering
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, -2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                spreadRadius: 0,
                                offset: const Offset(0, -1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isHovering ? Icons.delete_rounded : Icons.delete_outline_rounded,
                            key: ValueKey(isHovering),
                            color: isHovering
                                ? Colors.red
                                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            size: MediaQuery.of(context).size.width > 600 ? 26 : 22,
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width > 600 ? 12 : 8),
                        Flexible(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: isHovering
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: MediaQuery.of(context).size.width > 600 
                                      ? (isHovering ? 15 : 14)
                                      : (isHovering ? 14 : 13),
                                ),
                            textAlign: TextAlign.center,
                            child: Text(
                              isHovering 
                                  ? 'Bırakın, silinsin' 
                                  : MediaQuery.of(context).size.width > 600
                                      ? 'Görevleri buraya sürükleyerek silin'
                                      : 'Sürükleyerek silin',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

