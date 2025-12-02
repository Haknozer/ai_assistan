import 'package:flutter/material.dart';

/// Mesaj modeli - Tüm platform mesajları için ortak veri yapısı
class MessageModel {
  /// Supabase messages tablosundaki id (uuid)
  final String? id;
  final String platform;
  /// WhatsApp için telefon numarası (from_number)
  final String fromNumber;
  final String sender;
  final String subject;
  final String preview;
  final String? content;
  final String time;
  final String? date;
  final bool isUnread;
  final IconData icon;
  final Color color;
  /// Mesaj kullanıcının kendisinden mi gönderilmiş? (WhatsApp is_outgoing)
  final bool isOutgoing;

  const MessageModel({
    this.id,
    required this.platform,
    required this.fromNumber,
    required this.sender,
    required this.subject,
    required this.preview,
    this.content,
    required this.time,
    this.date,
    required this.isUnread,
    required this.icon,
    required this.color,
    this.isOutgoing = false,
  });

  /// İsimden baş harfleri al (Avatar için)
  String getInitials() {
    final parts = sender.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Kopyalama metodu
  MessageModel copyWith({
    String? id,
    String? platform,
    String? fromNumber,
    String? sender,
    String? subject,
    String? preview,
    String? content,
    String? time,
    String? date,
    bool? isUnread,
    IconData? icon,
    Color? color,
    bool? isOutgoing,
  }) {
    return MessageModel(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      fromNumber: fromNumber ?? this.fromNumber,
      sender: sender ?? this.sender,
      subject: subject ?? this.subject,
      preview: preview ?? this.preview,
      content: content ?? this.content,
      time: time ?? this.time,
      date: date ?? this.date,
      isUnread: isUnread ?? this.isUnread,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }
}

