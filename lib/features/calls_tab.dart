import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import 'call_screen.dart';

/// Call history, newest first. The trailing button calls the person again.
class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final calls = store.callLog;
    if (calls.isEmpty) {
      return Center(
        child: Text('No calls yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }
    final now = store.now;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: calls.length,
      itemBuilder: (context, i) {
        final entry = calls[i];
        final m = entry.message;
        final info = m.call!;
        final missedIncoming = info.missed && m.from == Sender.them;
        final c = entry.conversation;
        return ListTile(
          key: Key('call-${m.id}'),
          leading: ChatAvatar(name: c.name, color: c.color),
          title: Text(
            c.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: missedIncoming ? const Color(0xFFE53935) : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                m.from == Sender.me ? Icons.call_made : Icons.call_received,
                size: 14,
                color: missedIncoming ? const Color(0xFFE53935) : scheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${callTitle(m)} · ${dayLabel(m.at, now)}, ${formatTime(m.at)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Call again',
            icon: Icon(info.video ? Icons.videocam_outlined : Icons.call_outlined, color: scheme.primary),
            onPressed: () => startCall(context, c.id, video: info.video),
          ),
        );
      },
    );
  }
}
