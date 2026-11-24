import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'seed.dart';

/// All app state: conversations, search, typing indicator and theme.
///
/// Plain [ChangeNotifier], no packages. The clock, the reply delay and the
/// random source can be injected so tests stay fast and predictable.
class ChatStore extends ChangeNotifier {
  ChatStore({
    DateTime Function()? clock,
    this.replyDelay = const Duration(milliseconds: 1400),
    bool demo = true,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random() {
    if (demo) {
      _conversations = seedConversations(_clock());
      _activeId = _conversations.first.id;
    }
  }

  final DateTime Function() _clock;
  final Random _random;
  final Duration replyDelay;

  List<Conversation> _conversations = [];
  String? _activeId;
  String _query = '';
  String? _typingId;
  ThemeMode _themeMode = ThemeMode.system;
  Timer? _timer;

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  String get query => _query;
  String? get activeId => _activeId;
  ThemeMode get themeMode => _themeMode;
  DateTime get now => _clock();

  Conversation byId(String id) => _conversations.firstWhere((c) => c.id == id);

  Conversation? get active => _activeId == null ? null : byId(_activeId!);

  bool isTyping(String id) => _typingId == id;

  int get totalUnread => _conversations.fold(0, (sum, c) => sum + c.unread);

  /// Conversations that match the search, most recent first.
  List<Conversation> get visible {
    final q = _query.trim().toLowerCase();
    final list = _conversations.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.messages.any((m) => m.text.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => (b.last?.at ?? _epoch).compareTo(a.last?.at ?? _epoch));
    return list;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  /// Opens a conversation and marks it as read.
  void select(String id) {
    _activeId = id;
    _conversations = [
      for (final c in _conversations) c.id == id ? c.copyWith(unread: 0) : c,
    ];
    notifyListeners();
  }

  /// Sends a message. Blank text is ignored. The demo then "types" a reply.
  void send(String id, String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final at = _clock();
    final count = byId(id).messages.length;
    _append(id, Message(id: '$id-${at.microsecondsSinceEpoch}-$count', from: Sender.me, text: clean, at: at));
    _typingId = id;
    _timer?.cancel();
    _timer = Timer(replyDelay, () => _reply(id));
    notifyListeners();
  }

  void _reply(String id) {
    final at = _clock();
    final text = autoReplies[_random.nextInt(autoReplies.length)];
    _typingId = null;
    _append(id, Message(id: '$id-r-${at.microsecondsSinceEpoch}', from: Sender.them, text: text, at: at));
    notifyListeners();
  }

  void _append(String id, Message message) {
    _conversations = [
      for (final c in _conversations)
        c.id == id ? c.copyWith(messages: [...c.messages, message]) : c,
    ];
  }

  void toggleTheme(Brightness current) {
    _themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
