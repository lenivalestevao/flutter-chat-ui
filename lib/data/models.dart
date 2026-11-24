import 'package:flutter/material.dart';

enum Sender { me, them }

@immutable
class Message {
  const Message({
    required this.id,
    required this.from,
    required this.text,
    required this.at,
  });

  final String id;
  final Sender from;
  final String text;
  final DateTime at;
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.status,
    required this.color,
    this.unread = 0,
    this.messages = const [],
  });

  final String id;
  final String name;

  /// Short status such as "Online" or "Last seen 1h ago".
  final String status;
  final Color color;
  final int unread;
  final List<Message> messages;

  Message? get last => messages.isEmpty ? null : messages.last;

  Conversation copyWith({int? unread, List<Message>? messages}) {
    return Conversation(
      id: id,
      name: name,
      status: status,
      color: color,
      unread: unread ?? this.unread,
      messages: messages ?? this.messages,
    );
  }
}
