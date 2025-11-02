import 'package:flutter/material.dart';

/// Mesaj modeli - Tüm platform mesajları için ortak veri yapısı
class MessageModel {
  final String platform;
  final String sender;
  final String subject;
  final String preview;
  final String? content;
  final String time;
  final String? date;
  final bool isUnread;
  final IconData icon;
  final Color color;

  const MessageModel({
    required this.platform,
    required this.sender,
    required this.subject,
    required this.preview,
    this.content,
    required this.time,
    this.date,
    required this.isUnread,
    required this.icon,
    required this.color,
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
    String? platform,
    String? sender,
    String? subject,
    String? preview,
    String? content,
    String? time,
    String? date,
    bool? isUnread,
    IconData? icon,
    Color? color,
  }) {
    return MessageModel(
      platform: platform ?? this.platform,
      sender: sender ?? this.sender,
      subject: subject ?? this.subject,
      preview: preview ?? this.preview,
      content: content ?? this.content,
      time: time ?? this.time,
      date: date ?? this.date,
      isUnread: isUnread ?? this.isUnread,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}

