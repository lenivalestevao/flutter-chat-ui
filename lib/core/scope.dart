import 'package:flutter/widgets.dart';

import '../data/chat_store.dart';

/// Exposes the [ChatStore] to the widget tree and rebuilds dependents on change.
class ChatScope extends InheritedNotifier<ChatStore> {
  const ChatScope({super.key, required ChatStore store, required super.child})
      : super(notifier: store);

  static ChatStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChatScope>();
    assert(scope != null, 'No ChatScope found above this context');
    return scope!.notifier!;
  }
}
