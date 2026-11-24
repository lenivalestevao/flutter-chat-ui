import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/media_service.dart';
import 'models.dart';
import 'seed.dart';

/// All app state: conversations, search, typing indicator, read receipts,
/// voice message playback, call history and theme.
///
/// Plain [ChangeNotifier], no state management package. The clock, the delays
/// and the random source can be injected so tests stay fast and predictable.
class ChatStore extends ChangeNotifier {
  ChatStore({
    required this.media,
    DateTime Function()? clock,
    this.replyDelay = const Duration(milliseconds: 1400),
    this.callConnectDelay = const Duration(seconds: 2),
    bool demo = true,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random() {
    if (demo) {
      _conversations = seedConversations(_clock());
      _activeId = _conversations.first.id;
    }
    _positionSub = media.positionStream.listen((p) {
      if (_playingId != null) {
        _position = p;
        notifyListeners();
      }
    });
    _completeSub = media.completeStream.listen((_) => _stopPlayback());
  }

  final MediaService media;
  final DateTime Function() _clock;
  final Random _random;

  /// How long the other person takes to "type" a reply.
  final Duration replyDelay;

  /// How long a call rings before the other side "picks up".
  final Duration callConnectDelay;

  List<Conversation> _conversations = [];
  String? _activeId;
  String _query = '';
  String? _typingId;
  ThemeMode _themeMode = ThemeMode.system;
  Timer? _deliveredTimer;
  Timer? _replyTimer;
  Timer? _demoPlayTimer;
  String? _playingId;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

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

  /// Id of the voice message that is playing, if any.
  String? get playingId => _playingId;

  /// Playback position of the voice message that is playing.
  Duration get position => _position;

  /// Conversations that match the search, most recent first.
  List<Conversation> get visible {
    final q = _query.trim().toLowerCase();
    final list = _conversations.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.messages.any((m) => m.kind == MessageKind.text && m.text.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => (b.last?.at ?? _epoch).compareTo(a.last?.at ?? _epoch));
    return list;
  }

  /// Every call, newest first. This is the data behind the Calls tab.
  List<CallEntry> get callLog {
    final entries = [
      for (final c in _conversations)
        for (final m in c.messages)
          if (m.kind == MessageKind.call) CallEntry(c, m),
    ];
    entries.sort((a, b) => b.message.at.compareTo(a.message.at));
    return entries;
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

  // ---- Sending -------------------------------------------------------------

  /// Sends a text message. Blank text is ignored.
  void send(String id, String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final at = _clock();
    _post(id, Message(id: _nextId(id, at), from: Sender.me, at: at, text: clean));
  }

  void sendImage(String id, Uint8List bytes) {
    final at = _clock();
    _post(id, Message(id: _nextId(id, at), from: Sender.me, at: at, kind: MessageKind.image, imageBytes: bytes));
  }

  void sendAudio(String id, String path, Duration duration) {
    final at = _clock();
    _post(
      id,
      Message(id: _nextId(id, at), from: Sender.me, at: at, kind: MessageKind.audio, audioPath: path, audioDuration: duration),
    );
  }

  void sendLocation(String id, double latitude, double longitude) {
    final at = _clock();
    _post(
      id,
      Message(id: _nextId(id, at), from: Sender.me, at: at, kind: MessageKind.location, latitude: latitude, longitude: longitude),
    );
  }

  /// Adds an entry to the conversation and to the Calls tab.
  void logCall(
    String id, {
    required bool video,
    required Duration duration,
    Sender from = Sender.me,
    bool missed = false,
  }) {
    final at = _clock();
    _append(
      id,
      Message(
        id: _nextId(id, at),
        from: from,
        at: at,
        kind: MessageKind.call,
        call: CallInfo(video: video, duration: duration, missed: missed),
      ),
    );
    notifyListeners();
  }

  String _nextId(String id, DateTime at) => '$id-${at.microsecondsSinceEpoch}-${byId(id).messages.length}';

  /// Appends my message, then simulates delivery, "typing" and a reply.
  void _post(String id, Message message) {
    _append(id, message);
    _typingId = id;
    _deliveredTimer?.cancel();
    _replyTimer?.cancel();
    _deliveredTimer = Timer(replyDelay ~/ 3, () => _setDelivery(id, Delivery.delivered));
    _replyTimer = Timer(replyDelay, () => _reply(id, message.kind));
    notifyListeners();
  }

  void _setDelivery(String id, Delivery value) {
    _conversations = [
      for (final c in _conversations)
        if (c.id == id)
          c.copyWith(
            messages: [
              for (final m in c.messages)
                m.from == Sender.me && m.kind != MessageKind.call && m.delivery.index < value.index
                    ? m.copyWith(delivery: value)
                    : m,
            ],
          )
        else
          c,
    ];
    notifyListeners();
  }

  void _reply(String id, MessageKind to) {
    final at = _clock();
    final text = switch (to) {
      MessageKind.image => photoReply,
      MessageKind.audio => voiceReply,
      MessageKind.location => locationReply,
      _ => autoReplies[_random.nextInt(autoReplies.length)],
    };
    _typingId = null;
    _setDelivery(id, Delivery.read);
    _append(id, Message(id: '$id-r-${at.microsecondsSinceEpoch}', from: Sender.them, at: at, text: text));
    notifyListeners();
  }

  void _append(String id, Message message) {
    _conversations = [
      for (final c in _conversations)
        c.id == id ? c.copyWith(messages: [...c.messages, message]) : c,
    ];
  }

  // ---- Voice message playback ----------------------------------------------

  /// Plays or stops a voice message. Demo messages (empty path) are simulated.
  Future<void> togglePlay(Message m) async {
    final path = m.audioPath;
    if (path == null) return;
    if (_playingId == m.id) {
      final wasDemo = path.isEmpty;
      _stopPlayback();
      if (!wasDemo) await media.pause();
      return;
    }
    _stopPlayback();
    _playingId = m.id;
    _position = Duration.zero;
    notifyListeners();
    if (path.isEmpty) {
      _startDemoPlayback(m.audioDuration);
    } else {
      await media.play(path);
    }
  }

  void _startDemoPlayback(Duration total) {
    const step = Duration(milliseconds: 200);
    _demoPlayTimer = Timer.periodic(step, (_) {
      _position += step;
      if (_position >= total) {
        _stopPlayback();
      } else {
        notifyListeners();
      }
    });
  }

  void _stopPlayback() {
    _demoPlayTimer?.cancel();
    _demoPlayTimer = null;
    _playingId = null;
    _position = Duration.zero;
    notifyListeners();
  }

  // ---- Theme ---------------------------------------------------------------

  void toggleTheme(Brightness current) {
    _themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  @override
  void dispose() {
    _deliveredTimer?.cancel();
    _replyTimer?.cancel();
    _demoPlayTimer?.cancel();
    unawaited(_positionSub?.cancel());
    unawaited(_completeSub?.cancel());
    media.dispose();
    super.dispose();
  }
}
