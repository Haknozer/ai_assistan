import 'package:flutter/material.dart';
import '../../../services/task_notification_service.dart';

/// Görev bildirim zamanlama ayarları widget'ı
class TaskNotificationTimingCard extends StatefulWidget {
  const TaskNotificationTimingCard({super.key});

  @override
  State<TaskNotificationTimingCard> createState() => _TaskNotificationTimingCardState();
}

class _TaskNotificationTimingCardState extends State<TaskNotificationTimingCard> {
  final TaskNotificationService _notificationService = TaskNotificationService();
  final TextEditingController _customMinutesController = TextEditingController();
  int _selectedMinutes = 15; // Varsayılan değer
  bool _isLoading = true;
  bool _isCustomMode = false; // Özel değer modu

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSetting() async {
    final minutes = await _notificationService.getNotificationMinutesBefore();
    if (mounted) {
      setState(() {
        _selectedMinutes = minutes;
        _isLoading = false;
        // Eğer seçili değer hazır seçeneklerde yoksa, özel mod olarak işaretle
        final presetValues = [5, 15, 30, 60, 1440];
        _isCustomMode = !presetValues.contains(minutes);
        if (_isCustomMode) {
          _customMinutesController.text = minutes.toString();
        }
      });
    }
  }

  Future<void> _updateSetting(int minutes) async {
    setState(() => _selectedMinutes = minutes);
    await _notificationService.setNotificationMinutesBefore(minutes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim zamanı ${_formatMinutes(minutes)} önce olarak ayarlandı'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCustomTimeDialog() {
    _customMinutesController.text = _selectedMinutes.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel Bildirim Zamanı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kaç dakika önce bildirim almak istersiniz?'),
            const SizedBox(height: 16),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dakika',
                hintText: 'Örn: 20',
                suffixText: 'dakika',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Not: 1-10080 (7 gün) arasında bir değer giriniz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(_customMinutesController.text);
              if (value != null && value > 0 && value <= 10080) {
                setState(() {
                  _isCustomMode = true;
                });
                _updateSetting(value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen 1-10080 arasında geçerli bir değer girin'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Görev Bildirim Zamanlaması',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Görevlerinizin son tarihinden kaç dakika önce bildirim almak istersiniz?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Zaman seçenekleri
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTimeChip(5, '5 dakika'),
                  _buildTimeChip(15, '15 dakika'),
                  _buildTimeChip(30, '30 dakika'),
                  _buildTimeChip(60, '1 saat'),
                  _buildTimeChip(1440, '1 gün'),
                  // Özel değer butonu
                  _buildCustomChip(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Seçili değer gösterimi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Görevleriniz için ${_formatMinutes(_selectedMinutes)} önce bildirim alacaksınız',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(int minutes, String label) {
    final isSelected = _selectedMinutes == minutes && !_isCustomMode;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _isCustomMode = false;
          });
          _updateSetting(minutes);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildCustomChip() {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit, size: 16),
          const SizedBox(width: 4),
          Text(_isCustomMode ? _formatMinutes(_selectedMinutes) : 'Özel'),
        ],
      ),
      selected: _isCustomMode,
      onSelected: (selected) {
        _showCustomTimeDialog();
      },
      selectedColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.secondary,
      labelStyle: TextStyle(
        color: _isCustomMode
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: _isCustomMode ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: _isCustomMode
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      avatar: _isCustomMode ? const Icon(Icons.check_circle, size: 18) : null,
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes dakika';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours saat';
    } else {
      final days = minutes ~/ 1440;
      return '$days gün';
    }
  }
}

