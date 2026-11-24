import 'package:chatly_chat/core/format.dart';
import 'package:chatly_chat/data/chat_store.dart';
import 'package:chatly_chat/data/models.dart';
import 'package:chatly_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _now = DateTime(2026, 11, 24, 15);

ChatStore _store({Duration delay = Duration.zero, FakeMediaService? media}) => ChatStore(
      media: media ?? FakeMediaService(),
      clock: () => _now,
      replyDelay: delay,
      callConnectDelay: const Duration(milliseconds: 100),
    );

void main() {
  group('format helpers', () {
    test('initials', () {
      expect(initials('ana souza'), 'AS');
      expect(initials('Madonna'), 'M');
    });

    test('formatTime pads with zeros', () {
      expect(formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('formatDuration', () {
      expect(formatDuration(const Duration(seconds: 75)), '1:15');
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('call titles and previews', () {
      Message call(Sender from, {bool video = false, bool missed = false}) => Message(
            id: 'x',
            from: from,
            at: _now,
            kind: MessageKind.call,
            call: CallInfo(video: video, duration: Duration.zero, missed: missed),
          );
      expect(callTitle(call(Sender.them, video: true, missed: true)), 'Missed video call');
      expect(callTitle(call(Sender.me, missed: true)), 'Cancelled voice call');
      expect(callTitle(call(Sender.me)), 'Voice call');
      expect(previewText(call(Sender.me, video: true)), '📹 Video call');
      final audio = Message(
        id: 'y',
        from: Sender.me,
        at: _now,
        kind: MessageKind.audio,
        audioDuration: const Duration(seconds: 7),
      );
      expect(previewText(audio), '🎤 0:07');
    });

    test('dayLabel and groupByDay', () {
      final now = DateTime(2026, 11, 22, 15);
      Message msg(String id, DateTime at) => Message(id: id, from: Sender.them, text: id, at: at);
      final groups = groupByDay([
        msg('a', DateTime(2026, 11, 20, 10)),
        msg('b', DateTime(2026, 11, 21, 9)),
        msg('c', DateTime(2026, 11, 21, 18)),
        msg('d', DateTime(2026, 11, 22, 8)),
      ], now);
      expect(groups.map((g) => g.label).toList(), ['Nov 20', 'Yesterday', 'Today']);
      expect(groups[1].messages.length, 2);
    });
  });

  group('ChatStore', () {
    test('seeds demo conversations and counts unread', () {
      final store = _store();
      expect(store.conversations.length, 5);
      expect(store.totalUnread, 3);
      store.dispose();
    });

    test('filters by name or message text', () {
      final store = _store();
      store.setQuery('bruno');
      expect(store.visible.map((c) => c.id), ['bruno']);
      store.setQuery('INVOICE');
      expect(store.visible.map((c) => c.id), ['carla']);
      store.setQuery('zzz');
      expect(store.visible, isEmpty);
      store.dispose();
    });

    test('sorts by most recent message', () {
      final store = _store();
      expect(store.visible.first.id, 'ana');
      expect(store.visible.last.id, 'diego');
      store.dispose();
    });

    test('select marks a conversation as read', () {
      final store = _store();
      store.select('ana');
      expect(store.byId('ana').unread, 0);
      expect(store.totalUnread, 1);
      store.dispose();
    });

    test('send trims text, ignores blanks and then receives a reply', () async {
      final store = _store();
      final before = store.byId('bruno').messages.length;
      store.send('bruno', '   ');
      expect(store.byId('bruno').messages.length, before);

      store.send('bruno', '  Sure!  ');
      expect(store.byId('bruno').messages.length, before + 1);
      expect(store.byId('bruno').last?.text, 'Sure!');
      expect(store.isTyping('bruno'), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(store.isTyping('bruno'), isFalse);
      expect(store.byId('bruno').messages.length, before + 2);
      expect(store.byId('bruno').last?.from, Sender.them);
      store.dispose();
    });

    test('toggleTheme switches between dark and light', () {
      final store = _store();
      store.toggleTheme(Brightness.light);
      expect(store.themeMode, ThemeMode.dark);
      store.toggleTheme(Brightness.dark);
      expect(store.themeMode, ThemeMode.light);
      store.dispose();
    });
  });

  group('UI', () {
    testWidgets('wide layout shows both panes and a typing reply', (tester) async {
      final store = _store(delay: const Duration(milliseconds: 100));
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      expect(find.text('Chatly'), findsOneWidget);
      await tester.tap(find.text('Bruno Lima').first);
      await tester.pump();

      await tester.enterText(find.byKey(const Key('composer')), 'Hello!');
      await tester.pump();
      await tester.tap(find.byKey(const Key('send')));
      await tester.pump();

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.byKey(const Key('typing')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('typing')), findsNothing);
    });

    testWidgets('narrow layout opens the chat on a new screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = _store();
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      expect(find.byKey(const Key('composer')), findsNothing);
      await tester.tap(find.text('Carla Mendes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('composer')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('composer')), findsNothing);
    });
  });

  group('WhatsApp-style features', () {
    test('photo, voice and location messages get matching replies', () async {
      final store = _store();
      store.sendImage('bruno', tinyPng);
      expect(store.byId('bruno').last?.kind, MessageKind.image);
      await Future<void>.delayed(Duration.zero);
      expect(store.byId('bruno').last?.text, 'Nice photo! 😍');

      store.sendAudio('bruno', '/tmp/a.m4a', const Duration(seconds: 3));
      expect(store.byId('bruno').last?.kind, MessageKind.audio);
      await Future<void>.delayed(Duration.zero);
      expect(store.byId('bruno').last?.text, 'Got your voice message 👍');

      store.sendLocation('bruno', -23.5, -46.6);
      final shared = store.byId('bruno').last!;
      expect(shared.kind, MessageKind.location);
      expect(shared.latitude, -23.5);
      await Future<void>.delayed(Duration.zero);
      expect(store.byId('bruno').last?.text, 'Thanks, I am on my way 🚗');
      store.dispose();
    });

    test('ticks go sent, then delivered, then read', () async {
      final store = _store(delay: const Duration(milliseconds: 30));
      store.send('carla', 'hi');
      Delivery mine() => store.byId('carla').messages.lastWhere((m) => m.from == Sender.me).delivery;
      expect(mine(), Delivery.sent);
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(mine(), Delivery.delivered);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(mine(), Delivery.read);
      store.dispose();
    });

    test('logCall feeds the call log, newest first', () {
      final store = _store();
      final before = store.callLog.length;
      store.logCall('diego', video: true, duration: const Duration(seconds: 42));
      expect(store.callLog.length, before + 1);
      final first = store.callLog.first;
      expect(first.conversation.id, 'diego');
      expect(first.message.call?.video, isTrue);
      expect(first.message.call?.missed, isFalse);
      store.dispose();
    });

    test('demo voice message plays and stops', () async {
      final store = _store();
      final voice = store.byId('ana').messages.firstWhere((m) => m.kind == MessageKind.audio);
      await store.togglePlay(voice);
      expect(store.playingId, voice.id);
      await store.togglePlay(voice);
      expect(store.playingId, isNull);
      store.dispose();
    });

    test('recorded voice message uses the media service and stops when finished', () async {
      final media = FakeMediaService();
      final store = _store(media: media);
      store.sendAudio('diego', '/tmp/a.m4a', const Duration(seconds: 3));
      final msg = store.byId('diego').messages.firstWhere((m) => m.audioPath == '/tmp/a.m4a');
      await store.togglePlay(msg);
      expect(media.played, '/tmp/a.m4a');
      expect(store.playingId, msg.id);
      media.finishPlayback();
      await Future<void>.delayed(Duration.zero);
      expect(store.playingId, isNull);
      await Future<void>.delayed(Duration.zero);
      store.dispose();
      expect(media.disposed, isTrue);
    });
  });

  group('WhatsApp-style UI', () {
    testWidgets('calls tab lists the seeded calls', (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));
      await tester.tap(find.byKey(const Key('tab-calls')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Missed video call'), findsOneWidget);
      expect(find.byTooltip('Call again'), findsNWidgets(store.callLog.length));
    });

    testWidgets('voice call connects, counts time and is logged when ended', (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      final before = store.callLog.length;
      await tester.tap(find.byKey(const Key('voice-call')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Calling…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:01'), findsOneWidget);

      await tester.tap(find.byTooltip('End call'));
      await tester.pumpAndSettle();
      expect(store.callLog.length, before + 1);
      expect(store.callLog.first.message.call?.missed, isFalse);
      expect(store.callLog.first.message.call?.video, isFalse);
    });

    testWidgets('ending a call before it connects logs a cancelled call', (tester) async {
      final store = _store();
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      await tester.tap(find.byKey(const Key('video-call')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('self-view')), findsOneWidget);
      await tester.tap(find.byTooltip('End call'));
      await tester.pumpAndSettle();
      final entry = store.callLog.first.message;
      expect(entry.call?.missed, isTrue);
      expect(entry.call?.video, isTrue);
    });

    testWidgets('records and sends a voice message', (tester) async {
      final media = FakeMediaService();
      final store = _store(media: media, delay: const Duration(milliseconds: 100));
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      await tester.tap(find.byKey(const Key('mic')));
      await tester.pump();
      expect(find.byKey(const Key('recording')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('send-recording')));
      await tester.pump();
      await tester.pump();

      final last = store.active!.last!;
      expect(last.kind, MessageKind.audio);
      expect(last.audioPath, media.recordingPath);
      expect(find.byKey(const Key('recording')), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('a very short recording is discarded', (tester) async {
      final media = FakeMediaService();
      final store = _store(media: media);
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      final before = store.active!.messages.length;
      await tester.tap(find.byKey(const Key('mic')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('send-recording')));
      await tester.pump();
      await tester.pump();

      expect(media.recordingsCancelled, 1);
      expect(store.active!.messages.length, before);
    });

    testWidgets('attach menu shares the location', (tester) async {
      final store = _store(delay: const Duration(milliseconds: 100));
      addTearDown(store.dispose);
      await tester.pumpWidget(ChatlyApp(store: store));

      await tester.tap(find.byKey(const Key('attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attach-location')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await tester.pump();

      expect(store.active!.messages.any((m) => m.kind == MessageKind.location && m.from == Sender.me), isTrue);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
