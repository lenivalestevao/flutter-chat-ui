import 'dart:typed_data';

import 'package:flutter/material.dart';

enum Sender { me, them }

enum MessageKind { text, image, audio, location, call }

/// Ticks on my messages: one grey, two grey, two blue.
enum Delivery { sent, delivered, read }

@immutable
class CallInfo {
  const CallInfo({required this.video, required this.duration, this.missed = false});

  final bool video;
  final Duration duration;

  /// True when nobody picked up (a missed incoming call or a cancelled outgoing one).
  final bool missed;
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.from,
    required this.at,
    this.kind = MessageKind.text,
    this.text = '',
    this.delivery = Delivery.sent,
    this.imageBytes,
    this.audioPath,
    this.audioDuration = Duration.zero,
    this.latitude,
    this.longitude,
    this.call,
  });

  final String id;
  final Sender from;
  final DateTime at;
  final MessageKind kind;
  final String text;
  final Delivery delivery;

  /// Image messages.
  final Uint8List? imageBytes;

  /// Voice messages: a file path (or a blob URL on the web). Empty means demo audio.
  final String? audioPath;
  final Duration audioDuration;

  /// Location messages.
  final double? latitude;
  final double? longitude;

  /// Call log entries.
  final CallInfo? call;

  Message copyWith({Delivery? delivery}) {
    return Message(
      id: id,
      from: from,
      at: at,
      kind: kind,
      text: text,
      delivery: delivery ?? this.delivery,
      imageBytes: imageBytes,
      audioPath: audioPath,
      audioDuration: audioDuration,
      latitude: latitude,
      longitude: longitude,
      call: call,
    );
  }
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

  /// Short status such as "online" or "last seen 1h ago".
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

/// One row of the Calls tab.
@immutable
class CallEntry {
  const CallEntry(this.conversation, this.message);

  final Conversation conversation;
  final Message message;
}
