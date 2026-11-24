import 'package:chatly_chat/core/format.dart';
import 'package:chatly_chat/data/chat_store.dart';
import 'package:chatly_chat/data/models.dart';
import 'package:chatly_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 24, 15);

ChatStore _store({Duration delay = Duration.zero}) =>
    ChatStore(clock: () => _now, replyDelay: delay);

void main() {
  group('format helpers', () {
    test('initials', () {
      expect(initials('ana souza'), 'AS');
      expect(initials('Madonna'), 'M');
    });

    test('formatTime pads with zeros', () {
      expect(formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
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
}
