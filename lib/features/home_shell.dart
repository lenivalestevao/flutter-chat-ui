import 'package:flutter/material.dart';

import '../core/scope.dart';
import 'chat_pane.dart';
import 'conversations_pane.dart';

/// Two panes on wide screens (tablet, desktop, web). List then thread on phones.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const wideBreakpoint = 760.0;

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= wideBreakpoint) {
          final active = store.active;
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 340,
                  child: ConversationsPane(onOpen: store.select, highlightActive: true),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: active == null
                      ? const Center(child: Text('Select a conversation'))
                      : ChatPane(key: ValueKey(active.id), conversationId: active.id),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          body: ConversationsPane(
            onOpen: (id) {
              store.select(id);
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ChatPane(conversationId: id, showBack: true)),
              );
            },
          ),
        );
      },
    );
  }
}
