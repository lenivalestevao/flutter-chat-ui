import 'package:flutter/material.dart';

import 'core/scope.dart';
import 'core/theme.dart';
import 'data/chat_store.dart';
import 'features/home_shell.dart';

void main() => runApp(const ChatlyApp());

class ChatlyApp extends StatefulWidget {
  /// Pass a [store] to control the data (tests, previews). Otherwise the app owns one.
  const ChatlyApp({super.key, this.store});

  final ChatStore? store;

  @override
  State<ChatlyApp> createState() => _ChatlyAppState();
}

class _ChatlyAppState extends State<ChatlyApp> {
  late final ChatStore _store = widget.store ?? ChatStore();

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScope(
      store: _store,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          return MaterialApp(
            title: 'Chatly',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: _store.themeMode,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
