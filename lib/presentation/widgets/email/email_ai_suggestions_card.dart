import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/email.dart';
import '../../../models/calendar_event.dart';
import '../../../services/n8n_response_storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/screens/calendar/utils/calendar_utils.dart';
import 'calendar_event_confirmation_dialog.dart';

/// Email için AI önerileri kartı - n8n'den dönen AI önerilerini gösterir
/// Yeni format: [[{cevap: [...], tip: "gorev_listesi"}]]
class EmailAiSuggestionsCard extends ConsumerStatefulWidget {
  final Email email;

  const EmailAiSuggestionsCard({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailAiSuggestionsCard> createState() => _EmailAiSuggestionsCardState();
}

class _EmailAiSuggestionsCardState extends ConsumerState<EmailAiSuggestionsCard> {
  Map<String, dynamic>? _n8nResponse;
  bool _isLoading = true;
  String? _lastEmailId;

  @override
  void initState() {
    super.initState();
    _loadN8nResponse();
  }

  @override
  void didUpdateWidget(EmailAiSuggestionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentEmailId = widget.email.messageId ?? widget.email.id?.toString() ?? '';
    final oldEmailId = oldWidget.email.messageId ?? oldWidget.email.id?.toString() ?? '';
    
    if (currentEmailId != oldEmailId && currentEmailId != _lastEmailId) {
      _loadN8nResponse();
    }
  }

  Future<void> _loadN8nResponse() async {
    final emailId = widget.email.messageId ?? widget.email.id?.toString() ?? '';
    if (emailId.isEmpty) {
      setState(() {
        _isLoading = false;
        _lastEmailId = null;
        _n8nResponse = null;
      });
      return;
    }

    if (emailId == _lastEmailId) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastEmailId = emailId;
    });

    try {
      Map<String, dynamic>? response;
      if (widget.email.messageId != null && widget.email.messageId!.isNotEmpty) {
        response = await N8nResponseStorageService().getEmailResponse(widget.email.messageId!);
      }
      
      if (response == null && widget.email.id != null) {
        final idString = widget.email.id!.toString();
        response = await N8nResponseStorageService().getEmailResponse(idString);
      }
      
      // Response storage'dan gelen format: {'data': actualResponse, 'timestamp': '...'}
      // getEmailResponse zaten data'yı çıkarıyor, ama array ise ilk elemanı döndürüyor
      // Bu yüzden direkt response'u kullanabiliriz
      // Ama eğer response bir array ise, onu da handle etmeliyiz
      
      setState(() {
        _n8nResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('EmailAiSuggestionsCard - Error loading response', tag: 'N8N', error: e);
      setState(() {
        _isLoading = false;
        _n8nResponse = null;
      });
    }
  }

  /// Yeni formattan event'leri çıkar
  /// Format: [[{cevap: [...], tip: "gorev_listesi"}]] veya direkt event array
  List<Map<String, dynamic>> _extractEvents(dynamic response) {
    final events = <Map<String, dynamic>>[];

    try {
      // Özel format kontrolü: getEmailResponse'dan gelen array wrapper
      if (response is Map<String, dynamic> && response.containsKey('_isArray') && response['_isArray'] == true) {
        final arrayData = response['_arrayData'];
        if (arrayData is List) {
          response = arrayData; // Array'i direkt kullan
        }
      }
      
      // Önce response'un kendisini kontrol et
      if (response is List) {
        // Format 1: Direkt event array: [{baslik: "...", ...}, ...]
        bool allAreEvents = true;
        for (final item in response) {
          if (item is! Map<String, dynamic> || 
              (!item.containsKey('baslik') && !item.containsKey('durum'))) {
            allAreEvents = false;
            break;
          }
        }
        if (allAreEvents && response.isNotEmpty) {
          // Tüm elemanlar event, direkt ekle
          for (final item in response) {
            if (item is Map<String, dynamic>) {
              events.add(item);
            }
          }
          if (events.isNotEmpty) return events;
        }
        
        // Format 2: İç içe array yapısı: [[{cevap: [...], tip: "gorev_listesi"}]]
        if (response.isNotEmpty) {
          final firstLevel = response.first;
          
          if (firstLevel is List && firstLevel.isNotEmpty) {
            final secondLevel = firstLevel.first;
            if (secondLevel is Map<String, dynamic>) {
              // {cevap: [...], tip: "gorev_listesi"}
              if (secondLevel.containsKey('cevap') && secondLevel['cevap'] is List) {
                final cevapList = secondLevel['cevap'] as List;
                for (final item in cevapList) {
                  if (item is Map<String, dynamic>) {
                    events.add(item);
                  }
                }
                if (events.isNotEmpty) return events;
              }
            }
          }
        }
      }
      
      // Format 3: Map içinde cevap array'i
      if (response is Map<String, dynamic>) {
        if (response.containsKey('cevap') && response['cevap'] is List) {
          final cevapList = response['cevap'] as List;
          for (final item in cevapList) {
            if (item is Map<String, dynamic>) {
              events.add(item);
            }
          }
        }
        // Map içinde direkt event array'i
        if (response.containsKey('events') && response['events'] is List) {
          final eventsList = response['events'] as List;
          for (final item in eventsList) {
            if (item is Map<String, dynamic>) {
              events.add(item);
            }
          }
        }
        // Map içinde data array'i
        if (response.containsKey('data') && response['data'] is List) {
          final dataList = response['data'] as List;
          for (final item in dataList) {
            if (item is Map<String, dynamic> && 
                (item.containsKey('baslik') || item.containsKey('durum'))) {
              events.add(item);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Event extraction error', tag: 'EmailAI', error: e);
      AppLogger.debug('Response: $response', 'EmailAI');
    }

    return events;
  }

  DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> event) {
    final kategori = event['kategori'] as String?;
    showDialog(
      context: context,
      builder: (context) => CalendarEventConfirmationDialog(
        title: event['baslik'] ?? 'Etkinlik',
        description: event['detay'],
        startTime: _parseDateTime(event['baslangic']),
        endTime: _parseDateTime(event['bitis']),
        kategori: kategori,
        userMessage: event['kullanici_mesaji'] ?? 'Takvime eklenemedi',
        onEventAdded: () {
          // Event eklendikten sonra response'u güncelle ve UI'ı yenile
          _updateEventStatusInResponse(event['baslik'] as String? ?? '');
        },
      ),
    );
  }

  /// Event durumunu response'da güncelle (success olarak işaretle)
  Future<void> _updateEventStatusInResponse(String eventTitle) async {
    if (_n8nResponse == null) return;

    try {
      // Response'u güncelle - event'in durumunu "success" yap
      final updatedResponse = _updateEventStatus(_n8nResponse!, eventTitle, 'success');
      
      if (updatedResponse != null) {
        // Güncellenmiş response'u kaydet
        final emailId = widget.email.messageId ?? widget.email.id?.toString() ?? '';
        if (emailId.isNotEmpty) {
          await N8nResponseStorageService().saveEmailResponse(
            emailId,
            updatedResponse,
            receivedDate: widget.email.receivedDate,
          );
          
          // UI'ı yenile
          setState(() {
            _n8nResponse = updatedResponse;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Event durumu güncellenirken hata', tag: 'EmailAI', error: e);
    }
  }

  /// Response'da event durumunu güncelle
  dynamic _updateEventStatus(dynamic response, String eventTitle, String newStatus) {
    try {
      // Response'u kopyala
      dynamic updatedResponse;
      
      if (response is List) {
        updatedResponse = List.from(response);
        
        // İç içe array formatı: [[{cevap: [...], ...}]]
        if (updatedResponse.isNotEmpty && updatedResponse.first is List) {
          final firstLevel = List.from(updatedResponse.first as List);
          if (firstLevel.isNotEmpty && firstLevel.first is Map<String, dynamic>) {
            final secondLevel = Map<String, dynamic>.from(firstLevel.first as Map<String, dynamic>);
            
            if (secondLevel.containsKey('cevap') && secondLevel['cevap'] is List) {
              final cevapList = List.from(secondLevel['cevap'] as List);
              bool found = false;
              
              for (int i = 0; i < cevapList.length; i++) {
                if (cevapList[i] is Map<String, dynamic>) {
                  final event = Map<String, dynamic>.from(cevapList[i] as Map<String, dynamic>);
                  if (event['baslik'] == eventTitle) {
                    event['durum'] = newStatus;
                    event['kullanici_mesaji'] = 'Takvime başarıyla eklendi.';
                    cevapList[i] = event;
                    found = true;
                    break;
                  }
                }
              }
              
              if (found) {
                secondLevel['cevap'] = cevapList;
                firstLevel[0] = secondLevel;
                updatedResponse[0] = firstLevel;
                return updatedResponse;
              }
            }
          }
        }
        // Direkt event array formatı: [{baslik: "...", ...}, ...]
        else if (updatedResponse.isNotEmpty && updatedResponse.first is Map<String, dynamic>) {
          for (int i = 0; i < updatedResponse.length; i++) {
            if (updatedResponse[i] is Map<String, dynamic>) {
              final event = Map<String, dynamic>.from(updatedResponse[i] as Map<String, dynamic>);
              if (event['baslik'] == eventTitle) {
                event['durum'] = newStatus;
                event['kullanici_mesaji'] = 'Takvime başarıyla eklendi.';
                updatedResponse[i] = event;
                return updatedResponse;
              }
            }
          }
        }
      }
      
      // Map formatı
      if (response is Map<String, dynamic>) {
        updatedResponse = Map<String, dynamic>.from(response);
        
        if (updatedResponse.containsKey('cevap') && updatedResponse['cevap'] is List) {
          final cevapList = List.from(updatedResponse['cevap'] as List);
          for (int i = 0; i < cevapList.length; i++) {
            if (cevapList[i] is Map<String, dynamic>) {
              final event = Map<String, dynamic>.from(cevapList[i] as Map<String, dynamic>);
              if (event['baslik'] == eventTitle) {
                event['durum'] = newStatus;
                event['kullanici_mesaji'] = 'Takvime başarıyla eklendi.';
                cevapList[i] = event;
                updatedResponse['cevap'] = cevapList;
                return updatedResponse;
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Response güncellenirken hata', tag: 'EmailAI', error: e);
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_n8nResponse == null) {
      return const SizedBox.shrink();
    }

    // Event'leri çıkar
    final events = _extractEvents(_n8nResponse!);
    
    // Eğer event yoksa gizle
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Önerileri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Event'ler
          if (events.isNotEmpty) ...[
            if (events.length > 1)
              Text(
                'Takvim Etkinlikleri (${events.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            if (events.length > 1) const SizedBox(height: 8),
            ...events.map((event) => _buildEventCard(context, event)),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final durum = event['durum'] as String? ?? '';
    final baslik = event['baslik'] ?? 'Etkinlik';
    final detay = event['detay'] as String?;
    final baslangic = _parseDateTime(event['baslangic']);
    final kategori = event['kategori'] as String?;
    final isError = durum == 'error';
    final isSuccess = durum == 'success';
    
    // Kategori'den EventType'a çevir
    final eventType = EventType.fromCategory(kategori);
    final categoryColor = CalendarUtils.getEventTypeColor(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError 
            ? Colors.orange.withValues(alpha: 0.1)
            : isSuccess
                ? categoryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError
              ? Colors.orange.withValues(alpha: 0.3)
              : isSuccess
                  ? categoryColor.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
          width: isSuccess ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError
                    ? Icons.warning_amber_rounded
                    : isSuccess
                        ? CalendarUtils.getEventTypeIcon(eventType)
                        : Icons.event,
                color: isError
                    ? Colors.orange
                    : isSuccess
                        ? categoryColor
                        : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? categoryColor : null,
                          ),
                    ),
                    if (kategori != null && kategori.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getCategoryDisplayName(kategori),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isError)
                TextButton.icon(
                  onPressed: () => _showConfirmationDialog(event),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          if (baslangic != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(baslangic),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (detay != null && detay.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detay,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (isError && event['kullanici_mesaji'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['kullanici_mesaji'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSuccess) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Takvime eklendi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getCategoryDisplayName(String? kategori) {
    if (kategori == null || kategori.isEmpty) return '';
    switch (kategori.toLowerCase()) {
      case 'meeting':
        return 'Toplantı';
      case 'task':
        return 'Görev';
      case 'appointment':
        return 'Randevu';
      case 'social':
        return 'Sosyal';
      case 'personal':
        return 'Kişisel';
      default:
        return kategori.toUpperCase();
    }
  }
}
