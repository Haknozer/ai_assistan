import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/ai/models/chat_message.dart';

/// Supabase `chat_history` tablosundan sohbet geçmişini çeker ve cache'ler.
class ChatHistoryService {
  ChatHistoryService._internal({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService({SupabaseClient? client}) {
    if (client != null) {
      return ChatHistoryService._internal(client: client);
    }
    return _instance;
  }

  final SupabaseClient _supabase;
  final Map<String, List<ChatMessage>> _cache = {};
  final Map<String, bool> _loaded = {};

  /// Kullanıcının sohbet geçmişini zaman sırasına göre getirir.
  /// Cache'te varsa yeniden istek atmaz (forceRefresh ile zorlanabilir).
  Future<List<ChatMessage>> fetchHistory({
    required String userId,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _loaded[userId] == true && _cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    final response = await _fetchWithBestEffort(userId: userId, limit: limit);

    final messages = response
        .whereType<Map<String, dynamic>>()
        .map(_mapRowToMessage)
        .where((m) => m.text.trim().isNotEmpty)
        .toList();

    _cache[userId] = messages;
    _loaded[userId] = true;
    return messages;
  }

  List<ChatMessage>? getCachedMessages(String userId) => _cache[userId];
  bool isLoaded(String userId) => _loaded[userId] == true;

  Future<List<dynamic>> _fetchWithBestEffort({
    required String userId,
    required int limit,
  }) async {
    final columnsToTry = ['user_id', 'user_uuid'];
    PostgrestException? lastError;

    for (final col in columnsToTry) {
      try {
        final resp = await _supabase
            .from('chat_history')
            .select()
            .eq(col, userId)
            .order('created_at', ascending: true)
            .limit(limit);
        return resp;
      } on PostgrestException catch (e) {
        // Eğer kolon yoksa diğer kolonu dene
        if (e.message.contains('column') || e.message.contains('does not exist')) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    return [];
  }

  ChatMessage _mapRowToMessage(Map<String, dynamic> row) {
    final text = (row['message'] ?? row['text'] ?? '').toString();
    final isUser = _resolveIsUser(row);
    final ts = _parseTimestamp(row['created_at'] ?? row['timestamp']);

    return ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: ts,
    );
  }

  bool _resolveIsUser(Map<String, dynamic> row) {
    if (row.containsKey('is_user')) return row['is_user'] == true;
    if (row.containsKey('isUser')) return row['isUser'] == true;
    final sender = row['sender']?.toString().toLowerCase();
    final role = row['role']?.toString().toLowerCase();
    final actor = sender ?? role;
    if (actor == 'user' || actor == 'client' || actor == 'human') return true;
    if (actor == 'bot' || actor == 'assistant' || actor == 'ai') return false;
    return false;
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

