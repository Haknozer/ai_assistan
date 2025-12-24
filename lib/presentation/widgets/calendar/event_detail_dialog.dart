import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/calendar_event.dart';
import '../../../models/calendar_account.dart';
import '../../../providers/calendar_account_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../features/calendar/providers/calendar_provider.dart';
import '../../../core/utils/html_stripper.dart';
import '../../screens/calendar/utils/calendar_utils.dart';
import 'package:intl/intl.dart';

/// Event detay ve düzenleme dialog'u
class EventDetailDialog extends ConsumerStatefulWidget {
  final CalendarEvent event;
  final List<CalendarEvent> allEvents; // Tüm event listesi (duplicate kontrolü için)
  final VoidCallback? onEventUpdated;
  final VoidCallback? onEventDeleted;

  const EventDetailDialog({
    super.key,
    required this.event,
    required this.allEvents,
    this.onEventUpdated,
    this.onEventDeleted,
  });

  @override
  ConsumerState<EventDetailDialog> createState() => _EventDetailDialogState();
}

class _EventDetailDialogState extends ConsumerState<EventDetailDialog> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  EventType? _eventType;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description ?? '';
    _locationController.text = widget.event.location ?? '';
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _eventType = widget.event.eventType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Aynı event'in duplicate versiyonlarını bul (hem Google hem Outlook'ta varsa)
  /// EventMerger ile aynı mantığı kullanır
  /// NOT: allEvents listesi merge edilmiş event'leri içerir, bu yüzden duplicate'leri bulmak için
  /// mevcut event'in bilgilerine göre diğer source'dan event'i bulmaya çalışırız
  List<CalendarEvent> _findDuplicateEvents() {
    final duplicates = <CalendarEvent>[widget.event];
    final addedEventKeys = <String>{};

    // Mevcut event'in key'lerini oluştur (EventMerger ile aynı mantık)
    final currentEventKey = _getEventKey(widget.event);
    final currentDetailKey = _getEventDetailKey(widget.event);
    addedEventKeys.add('${widget.event.source.name}|$currentEventKey');

    debugPrint('🔍 Duplicate arama başladı');
    debugPrint('   - Mevcut event: "${widget.event.title}" (${widget.event.source.name})');
    debugPrint('   - Mevcut event key: $currentEventKey');
    debugPrint('   - Mevcut event detail key: $currentDetailKey');
    debugPrint('   - Tüm event sayısı: ${widget.allEvents.length}');
    debugPrint('   - External ID: ${widget.event.externalId}');

    // Önce allEvents listesinde ara (merge edilmiş event'ler arasında)
    for (final otherEvent in widget.allEvents) {
      // Aynı event'i atla (id, source ve externalId aynıysa)
      if (otherEvent.id == widget.event.id &&
          otherEvent.source == widget.event.source &&
          otherEvent.externalId == widget.event.externalId) {
        continue;
      }

      // EventMerger ile aynı key mantığını kullan
      final otherEventKey = _getEventKey(otherEvent);
      final otherDetailKey = _getEventDetailKey(otherEvent);

      // Başlık + zaman aynı mı? (EventMerger mantığı)
      final sameEventKey = otherEventKey == currentEventKey;

      // Veya detay + zaman aynı mı? (EventMerger mantığı)
      final sameDetailKey = otherDetailKey == currentDetailKey;

      if (sameEventKey || sameDetailKey) {
        // Bu event'i daha önce ekledik mi kontrol et (source + key kombinasyonu)
        final eventKeyWithSource = '${otherEvent.source.name}|$otherEventKey';

        if (!addedEventKeys.contains(eventKeyWithSource)) {
          duplicates.add(otherEvent);
          addedEventKeys.add(eventKeyWithSource);
          debugPrint(
              '🔍 Duplicate event bulundu (allEvents içinde): "${otherEvent.title}" (${otherEvent.source.name})');
          debugPrint('   - Event Key eşleşmesi: $sameEventKey');
          debugPrint('   - Detail Key eşleşmesi: $sameDetailKey');
          debugPrint('   - External ID: ${otherEvent.externalId}');
          debugPrint('   - Start Time: ${otherEvent.startTime}');
        }
      }
    }

    // Eğer allEvents'te duplicate bulunamadıysa, mevcut event'in bilgilerine göre
    // diğer source'dan event'i oluştur (silme işlemi için)
    // Bu durumda merge işlemi duplicate'leri filtrelemiş olabilir
    if (duplicates.length == 1) {
      // Diğer source'u belirle
      final otherSource = widget.event.source == EventSource.google
          ? EventSource.outlook
          : (widget.event.source == EventSource.outlook ? EventSource.google : null);

      if (otherSource != null) {
        // Diğer source'dan event oluştur (external ID olmadan, sadece bilgilerle)
        // Bu event'i silme işlemi sırasında API'den bulacağız
        final duplicateEvent = CalendarEvent(
          userId: widget.event.userId,
          title: widget.event.title,
          description: widget.event.description,
          startTime: widget.event.startTime,
          endTime: widget.event.endTime,
          location: widget.event.location,
          eventType: widget.event.eventType,
          source: otherSource,
          externalId: null, // API'den bulunacak
          createdAt: widget.event.createdAt,
          updatedAt: widget.event.updatedAt,
        );

        duplicates.add(duplicateEvent);
        debugPrint(
            '🔍 Diğer source\'dan duplicate event oluşturuldu: "${duplicateEvent.title}" (${duplicateEvent.source.name})');
        debugPrint('   - NOT: Bu event\'in external ID\'si silme işlemi sırasında API\'den bulunacak');
      }
    }

    debugPrint('🔍 Toplam ${duplicates.length} duplicate event bulundu (Google ve Outlook dahil)');
    if (duplicates.length > 1) {
      debugPrint('🔍 Duplicate source\'lar: ${duplicates.map((e) => e.source.name).join(", ")}');
    }
    return duplicates;
  }

  /// Event için unique key oluştur (title + startTime) - EventMerger ile aynı mantık
  String _getEventKey(CalendarEvent event) {
    // Başlığı normalize et (küçük harf, boşlukları temizle)
    final normalizedTitle = event.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // Start time'ı saat bazında normalize et (dakika ve saniyeyi yok say)
    // Bu sayede timezone farklarından kaynaklanan küçük farkları görmezden geliriz
    final normalizedTime = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
      event.startTime.hour,
    );

    return '$normalizedTitle|${normalizedTime.toIso8601String()}';
  }

  /// Event için detay + saat key'i oluştur (başlık + saat aynı değilse kullanılır) - EventMerger ile aynı mantık
  String _getEventDetailKey(CalendarEvent event) {
    // Detayı önce HTML'den temizle (eğer HTML içeriyorsa), sonra normalize et
    String? cleanedDescription = event.description;
    if (cleanedDescription != null && cleanedDescription.isNotEmpty) {
      cleanedDescription = HtmlStripper.cleanIfNeeded(cleanedDescription);
    }

    // Detayı normalize et (küçük harf, boşlukları temizle)
    final normalizedDescription = (cleanedDescription ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // Eğer detay boşsa, başlığı kullan
    final keyContent = normalizedDescription.isEmpty
        ? event.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ')
        : normalizedDescription;

    // Start time'ı saat bazında normalize et
    final normalizedTime = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
      event.startTime.hour,
    );

    return '$keyContent|${normalizedTime.toIso8601String()}';
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık zorunludur')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlangıç ve bitiş zamanı zorunludur')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş zamanı başlangıç zamanından önce olamaz')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Duplicate event'leri bul
      final duplicateEvents = _findDuplicateEvents();

      // Event'in source'una göre calendar account bul
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
        userId: currentUser.id,
      )));

      final calendarAccounts = calendarAccountsAsync.value ?? [];
      if (calendarAccounts.isEmpty) {
        throw Exception('Calendar hesabı bulunamadı');
      }

      final repository = ref.read(calendarRepositoryProvider);

      // Tüm duplicate event'leri paralel olarak güncelle (hem Google hem Outlook'ta varsa aynı anda)
      final updateFutures = <Future>[];

      for (final duplicateEvent in duplicateEvents) {
        CalendarAccount? account;

        if (duplicateEvent.source == EventSource.google) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.google && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        } else if (duplicateEvent.source == EventSource.outlook) {
          account = calendarAccounts.firstWhere(
            (acc) => acc.provider == CalendarProvider.outlook && acc.isActive,
            orElse: () => calendarAccounts.first,
          );
        }

        if (account == null || account.accessToken == null || account.accessToken!.isEmpty) {
          continue; // Bu source için account yoksa atla
        }

        // External ID kullan (Google/Outlook event ID)
        final eventId = duplicateEvent.externalId ?? duplicateEvent.id?.toString() ?? '';
        if (eventId.isEmpty) {
          continue; // Event ID yoksa atla
        }

        // Paralel güncelleme için future ekle
        final accountProvider = account.provider;
        final accountUserId = account.userId;
        updateFutures.add(
          repository
              .updateEvent(
            eventId: eventId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            eventType: _eventType,
            calendarId: 'primary',
            accessToken: account.accessToken!,
            provider: accountProvider,
            userId: accountUserId,
          )
              .catchError((e) {
            debugPrint('Event güncelleme hatası ($accountProvider): $e');
            // Bir calendar'da hata olsa bile diğerini güncellemeye devam et
            // Hata durumunda null döndür (Future.wait için)
            return CalendarEvent(
              userId: accountUserId,
              title: '',
              startTime: DateTime.now(),
              endTime: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }),
        );
      }

      // Tüm güncelleme işlemlerini paralel olarak bekle
      await Future.wait(updateFutures);

      if (mounted) {
        // Önce callback'i çağır (provider'ı refresh et) - dialog kapanmadan önce
        widget.onEventUpdated?.call();

        // Kısa bir gecikme ile dialog'u kapat (provider refresh'in tamamlanması için)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Etkinlik güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteEvent() async {
    // Duplicate event'leri önce bul (kullanıcıya bilgi vermek için)
    final duplicateEvents = _findDuplicateEvents();
    final hasMultipleSources = duplicateEvents.length > 1;

    String confirmMessage = 'Bu etkinliği silmek istediğinizden emin misiniz?';
    if (hasMultipleSources) {
      final sources = duplicateEvents.map((e) => e.source == EventSource.google ? 'Google' : 'Outlook').join(' ve ');
      confirmMessage =
          'Bu etkinlik $sources takvimlerinde mevcut. Tüm takvimlerden silmek istediğinizden emin misiniz?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final calendarAccountsAsync = ref.read(calendarAccountsProvider(CalendarAccountsParams(
        userId: currentUser.id,
      )));

      final calendarAccounts = calendarAccountsAsync.value ?? [];
      if (calendarAccounts.isEmpty) {
        throw Exception('Calendar hesabı bulunamadı');
      }

      final repository = ref.read(calendarRepositoryProvider);

      // Tüm duplicate event'leri paralel olarak sil (hem Google hem Outlook'ta varsa aynı anda)
      final deleteFutures = <Future>[];
      final deletedSources = <String>{}; // Hangi source'lardan silindi (log için)
      final errorMessages = <String>[]; // Hata mesajları

      for (final duplicateEvent in duplicateEvents) {
        CalendarAccount? account;

        // Account bulma mantığını iyileştir
        try {
          if (duplicateEvent.source == EventSource.google) {
            account = calendarAccounts.firstWhere(
              (acc) =>
                  acc.provider == CalendarProvider.google &&
                  acc.isActive &&
                  acc.accessToken != null &&
                  acc.accessToken!.isNotEmpty,
            );
          } else if (duplicateEvent.source == EventSource.outlook) {
            account = calendarAccounts.firstWhere(
              (acc) =>
                  acc.provider == CalendarProvider.outlook &&
                  acc.isActive &&
                  acc.accessToken != null &&
                  acc.accessToken!.isNotEmpty,
            );
          } else {
            // Manuel veya diğer source'lar için atla (sadece Google ve Outlook'tan silebiliriz)
            debugPrint('⚠️ Event source desteklenmiyor: ${duplicateEvent.source.name}');
            continue;
          }
        } catch (e) {
          // Account bulunamadı
          debugPrint('⚠️ ${duplicateEvent.source.name} için aktif account bulunamadı');
          errorMessages
              .add('${duplicateEvent.source == EventSource.google ? "Google" : "Outlook"} takvim hesabı bulunamadı');
          continue;
        }

        // Account bulundu, access token kontrolü yap
        if (account.accessToken == null || account.accessToken!.isEmpty) {
          debugPrint('⚠️ ${duplicateEvent.source.name} için access token bulunamadı');
          errorMessages.add(
              '${duplicateEvent.source == EventSource.google ? "Google" : "Outlook"} takvim erişim token\'ı bulunamadı');
          continue;
        }

        // Event ID'yi bul (external ID yoksa API'den bul)
        String? eventId = duplicateEvent.externalId;
        final sourceDisplayName = duplicateEvent.source == EventSource.google ? 'Google' : 'Outlook';

        if (eventId == null || eventId.isEmpty) {
          // External ID yoksa, API'den event'leri çekip title + startTime'a göre bul
          debugPrint('🔍 External ID yok, API\'den event aranıyor: ${duplicateEvent.title} ($sourceDisplayName)');

          try {
            // Event'in zamanına yakın bir aralıkta event'leri çek (±1 gün)
            final searchTimeMin = duplicateEvent.startTime.subtract(const Duration(days: 1));
            final searchTimeMax = duplicateEvent.startTime.add(const Duration(days: 1));

            final events = await repository.getEvents(
              calendarId: 'primary',
              timeMin: searchTimeMin,
              timeMax: searchTimeMax,
              accessToken: account.accessToken!,
              provider: account.provider,
              userId: currentUser.id,
            );

            // Title + startTime'a göre eşleşen event'i bul
            final normalizedTitle = duplicateEvent.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
            CalendarEvent? matchingEvent;

            for (final event in events) {
              final eventNormalizedTitle = event.title.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
              final timeDiff = (event.startTime.difference(duplicateEvent.startTime).inHours).abs();

              if (eventNormalizedTitle == normalizedTitle &&
                  timeDiff <= 1 &&
                  event.startTime.year == duplicateEvent.startTime.year &&
                  event.startTime.month == duplicateEvent.startTime.month &&
                  event.startTime.day == duplicateEvent.startTime.day) {
                matchingEvent = event;
                break;
              }
            }

            if (matchingEvent != null && matchingEvent.externalId != null) {
              eventId = matchingEvent.externalId;
              debugPrint('✅ Event bulundu: ${matchingEvent.title} (ID: $eventId)');
            } else {
              debugPrint('⚠️ Event bulunamadı: ${duplicateEvent.title} ($sourceDisplayName)');
              errorMessages.add('$sourceDisplayName takviminde "${duplicateEvent.title}" etkinliği bulunamadı');
              continue;
            }
          } catch (e) {
            debugPrint('❌ Event arama hatası ($sourceDisplayName): $e');
            errorMessages.add('$sourceDisplayName takviminde event aranırken hata: ${e.toString()}');
            continue;
          }
        }

        if (eventId == null || eventId.isEmpty) {
          debugPrint('⚠️ Event ID hala boş: ${duplicateEvent.title} (${duplicateEvent.source.name})');
          errorMessages
              .add('${duplicateEvent.source == EventSource.google ? "Google" : "Outlook"} etkinlik ID\'si bulunamadı');
          continue;
        }

        // Paralel silme için future ekle
        final finalEventId = eventId; // Null safety için
        deleteFutures.add(
          repository
              .deleteEvent(
            eventId: finalEventId,
            calendarId: 'primary',
            accessToken: account.accessToken!,
            provider: account.provider,
          )
              .then((_) {
            deletedSources.add(sourceDisplayName);
            debugPrint('✅ Event silindi: ${duplicateEvent.title} ($sourceDisplayName)');
          }).catchError((e) {
            debugPrint('❌ Event silme hatası ($sourceDisplayName): $e');
            errorMessages.add('$sourceDisplayName takviminden silinirken hata: ${e.toString()}');
            // Bir calendar'da hata olsa bile diğerini silmeye devam et
          }),
        );
      }

      // Tüm silme işlemlerini paralel olarak bekle
      await Future.wait(deleteFutures, eagerError: false);

      if (deletedSources.isNotEmpty) {
        debugPrint('✅ Toplam ${deletedSources.length} calendar\'dan event silindi: ${deletedSources.join(", ")}');
      }

      if (mounted) {
        // Önce callback'i çağır (provider'ı invalidate et) - dialog kapanmadan önce
        widget.onEventDeleted?.call();

        // Kısa bir gecikme ile dialog'u kapat (provider refresh'in başlaması için)
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.pop(context);

            // Başarı/hata mesajı göster
            if (deletedSources.isNotEmpty && errorMessages.isEmpty) {
              // Tüm silme işlemleri başarılı
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(hasMultipleSources
                      ? 'Etkinlik tüm takvimlerden silindi (${deletedSources.join(", ")})'
                      : 'Etkinlik silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (deletedSources.isNotEmpty && errorMessages.isNotEmpty) {
              // Kısmen başarılı
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Etkinlik ${deletedSources.join(", ")} takvimlerinden silindi. Bazı hatalar: ${errorMessages.join("; ")}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            } else {
              // Hiç silinemedi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Etkinlik silinemedi: ${errorMessages.join("; ")}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      // End time'ı da otomatik ayarla (eğer end time yoksa veya start time'dan önceyse)
      if (_endTime == null || _endTime!.isBefore(_startTime!)) {
        _endTime = _startTime!.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce başlangıç zamanını seçin')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime!,
      firstDate: _startTime!,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? _startTime!.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    if (!mounted) return;

    final selectedEndTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    if (selectedEndTime.isBefore(_startTime!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş zamanı başlangıç zamanından önce olamaz')),
      );
      return;
    }

    setState(() {
      _endTime = selectedEndTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = CalendarUtils.getEventTypeColor(widget.event.eventType);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CalendarUtils.getEventTypeIcon(widget.event.eventType),
                    color: eventColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Etkinliği Düzenle' : 'Etkinlik Detayları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _initializeForm(); // Reset form
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isEditing ? _buildEditForm() : _buildDetailView(context, eventColor),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isEditing) ...[
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                _initializeForm();
                              });
                            },
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEvent,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: _isDeleting ? null : _deleteEvent,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete, size: 18),
                      label: const Text('Sil'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Düzenle'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Color eventColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Text(
          widget.event.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Zaman
        _buildDetailRow(
          icon: Icons.access_time,
          label: 'Zaman',
          value:
              '${CalendarUtils.formatDateTime(widget.event.startTime)} - ${CalendarUtils.formatTime(widget.event.endTime)}',
        ),

        // Süre
        _buildDetailRow(
          icon: Icons.schedule,
          label: 'Süre',
          value: CalendarUtils.calculateDuration(widget.event.startTime, widget.event.endTime),
        ),

        // Lokasyon
        if (widget.event.location != null && widget.event.location!.isNotEmpty)
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Lokasyon',
            value: widget.event.location!,
          ),

        // Açıklama
        if (widget.event.description != null && widget.event.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Açıklama',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            HtmlStripper.cleanIfNeeded(widget.event.description!),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],

        // Kaynak (duplicate varsa tüm source'ları göster)
        const SizedBox(height: 16),
        Row(
          children: [
            // Tüm source'ları göster (duplicate varsa)
            ..._findDuplicateEvents().map((event) {
              final color = CalendarUtils.getEventSourceColor(event.source);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CalendarUtils.getEventSourceIcon(event.source),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.source == EventSource.google
                          ? 'Google'
                          : event.source == EventSource.outlook
                              ? 'Outlook'
                              : 'Manuel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Başlık *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Başlangıç zamanı
        InkWell(
          onTap: _selectStartTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Başlangıç Zamanı *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _startTime != null ? DateFormat('dd.MM.yyyy HH:mm').format(_startTime!) : 'Seçin',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bitiş zamanı
        InkWell(
          onTap: _selectEndTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Bitiş Zamanı *',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _endTime != null ? DateFormat('dd.MM.yyyy HH:mm').format(_endTime!) : 'Seçin',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lokasyon
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Lokasyon',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),

        // Açıklama
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Açıklama',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Event Type
        DropdownButtonFormField<EventType>(
          initialValue: _eventType,
          decoration: const InputDecoration(
            labelText: 'Etkinlik Türü',
            border: OutlineInputBorder(),
          ),
          items: EventType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getEventTypeName(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _eventType = value;
            });
          },
        ),
      ],
    );
  }

  String _getEventTypeName(EventType type) {
    switch (type) {
      case EventType.meeting:
        return 'Toplantı';
      case EventType.appointment:
        return 'Randevu';
      case EventType.task:
        return 'Görev';
      case EventType.personal:
        return 'Kişisel';
      case EventType.other:
        return 'Diğer';
    }
  }
}
