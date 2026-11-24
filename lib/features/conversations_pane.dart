import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import 'calls_tab.dart';

/// Header, search field and the list of conversations.
class ConversationsPane extends StatelessWidget {
  const ConversationsPane({super.key, required this.onOpen, this.highlightActive = false});

  final void Function(String id) onOpen;

  /// Highlights the open conversation (used on wide screens with two panes).
  final bool highlightActive;

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final theme = Theme.of(context);
    final list = store.visible;
    final unread = store.totalUnread;

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Text('Chatly', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  if (unread > 0) ...[const SizedBox(width: 10), CountBadge(unread)],
                  const Spacer(),
                  IconButton(
                    tooltip: theme.brightness == Brightness.dark ? 'Switch to light theme' : 'Switch to dark theme',
                    onPressed: () => store.toggleTheme(theme.brightness),
                    icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(key: Key('tab-chats'), text: 'Chats'),
                Tab(key: Key('tab-calls'), text: 'Calls'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          key: const Key('search'),
                          onChanged: store.setQuery,
                          decoration: InputDecoration(
                            hintText: 'Search chats',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Text('No chats match your search.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: list.length,
                                itemBuilder: (context, i) => _ConversationTile(
                                  conversation: list[i],
                                  selected: highlightActive && list[i].id == store.activeId,
                                  onTap: () => onOpen(list[i].id),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const CallsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.selected, required this.onTap});

  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = conversation.last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ChatAvatar(name: conversation.name, color: conversation.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (last != null)
                            Text(formatTime(last.at), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview(conversation),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          if (conversation.unread > 0) ...[const SizedBox(width: 8), CountBadge(conversation.unread)],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
