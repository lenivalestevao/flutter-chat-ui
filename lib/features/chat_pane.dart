import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../core/widgets.dart';
import 'bubbles.dart';
import 'call_screen.dart';
import 'composer.dart';

/// Header, messages and composer for one conversation.
class ChatPane extends StatefulWidget {
  const ChatPane({super.key, required this.conversationId, this.showBack = false});

  final String conversationId;
  final bool showBack;

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final _scroll = ScrollController();
  String? _lastId;
  int _lastCount = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = store.byId(widget.conversationId);
    final typing = store.isTyping(c.id);

    final count = c.messages.length + (typing ? 1 : 0);
    if (count != _lastCount || c.id != _lastId) {
      _lastCount = count;
      _lastId = c.id;
      _scrollToEnd();
    }

    final groups = groupByDay(c.messages, store.now);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBack ? const BackButton() : null,
        titleSpacing: widget.showBack ? 0 : 16,
        title: Row(
          children: [
            ChatAvatar(name: c.name, color: c.color, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(typing ? 'typing…' : c.status, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('video-call'),
            tooltip: 'Video call',
            onPressed: () => startCall(context, c.id, video: true),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            key: const Key('voice-call'),
            tooltip: 'Voice call',
            onPressed: () => startCall(context, c.id, video: false),
            icon: const Icon(Icons.call_outlined),
          ),
        ],
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              children: [
                for (final g in groups) ...[
                  _DayChip(g.label),
                  for (final m in g.messages) MessageBubble(message: m),
                ],
                if (typing) const _TypingBubble(),
              ],
            ),
          ),
          Composer(conversationId: c.id),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('typing'),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: const TypingDots(),
      ),
    );
  }
}
