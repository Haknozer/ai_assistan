import 'package:flutter/material.dart';
import '../../../models/calendar_event.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/calendar/utils/calendar_utils.dart';

/// Etkinlik ekleme dialog'u widget'ı
class AddEventDialog extends StatefulWidget {
  final Function(CalendarEvent) onEventAdded;

  const AddEventDialog({
    super.key,
    required this.onEventAdded,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  EventType _selectedType = EventType.meeting;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    // End time start time'dan önce olamaz
    final finalEndTime = endDateTime.isBefore(startDateTime) 
        ? startDateTime.add(const Duration(hours: 1))
        : endDateTime;

    final newEvent = CalendarEvent(
      id: null, // Google Calendar'a eklenecek, ID oradan gelecek
      userId: 0, // Calendar screen'den geçirilecek
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startTime: startDateTime,
      endTime: finalEndTime,
      eventType: _selectedType,
      source: EventSource.manual,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onEventAdded(newEvent);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(context),
                      const SizedBox(height: 16),
                      _buildDescriptionField(context),
                      const SizedBox(height: 16),
                      _buildLocationField(context),
                      const SizedBox(height: 16),
                      _buildEventTypeSelector(context),
                      const SizedBox(height: 16),
                      _buildDateSelector(context),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStartTimeSelector(context)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildEndTimeSelector(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.add_circle_outline,
            color: AppTheme.primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          'Yeni Etkinlik Ekle',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Etkinlik Başlığı *',
        hintText: 'Başlık girin...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Başlık zorunludur' : null,
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Açıklama',
        hintText: 'Açıklama girin (opsiyonel)...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildLocationField(BuildContext context) {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Konum',
        hintText: 'Konum girin (opsiyonel)...',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildEventTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etkinlik Tipi',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: EventType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
              backgroundColor: AppColors.getCardColor(context),
              selectedColor: CalendarUtils.getEventTypeColor(type)
                  .withValues(alpha: 0.2),
              checkmarkColor: CalendarUtils.getEventTypeColor(type),
              labelStyle: TextStyle(
                color: isSelected
                    ? CalendarUtils.getEventTypeColor(type)
                    : AppColors.getPrimaryTextColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? CalendarUtils.getEventTypeColor(type)
                    : AppColors.getBorderColor(context),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tarih *',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _selectedDate != null
              ? CalendarUtils.formatDate(_selectedDate!)
              : 'Tarih seçin',
          style: TextStyle(
            color: _selectedDate != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStartTimeSelector(BuildContext context) {
    return InkWell(
      onTap: _selectStartTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Başlangıç *',
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _startTime != null ? _startTime!.format(context) : 'Saat seçin',
          style: TextStyle(
            color: _startTime != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEndTimeSelector(BuildContext context) {
    return InkWell(
      onTap: _selectEndTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Bitiş *',
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _endTime != null ? _endTime!.format(context) : 'Saat seçin',
          style: TextStyle(
            color: _endTime != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.getBorderColor(context)),
            ),
            child: Text(
              'İptal',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Etkinlik Ekle'),
          ),
        ),
      ],
    );
  }
}

