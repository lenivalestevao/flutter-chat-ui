import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../core/theme.dart';
import '../data/models.dart';
import 'image_viewer.dart';

/// One chat bubble. Picks the right layout for text, photo, voice message,
/// location or call entry.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.from == Sender.me;
    final bg = mine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    final maxWidth = min(460.0, MediaQuery.sizeOf(context).width * 0.75);
    final isImage = message.kind == MessageKind.image;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: isImage ? const EdgeInsets.all(4) : const EdgeInsets.fromLTRB(12, 8, 10, 6),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: switch (message.kind) {
          MessageKind.text => _TextBody(message: message, fg: fg),
          MessageKind.image => _ImageBody(message: message, maxWidth: maxWidth),
          MessageKind.audio => _AudioBody(message: message, fg: fg),
          MessageKind.location => _LocationBody(message: message, fg: fg),
          MessageKind.call => _CallBody(message: message, fg: fg),
        },
      ),
    );
  }
}

/// Time and, on my messages, the delivery ticks.
class _Meta extends StatelessWidget {
  const _Meta({required this.message, required this.color});

  final Message message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final showTicks = message.from == Sender.me && message.kind != MessageKind.call;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatTime(message.at), style: TextStyle(color: color.withValues(alpha: 0.65), fontSize: 11)),
        if (showTicks) ...[
          const SizedBox(width: 3),
          Icon(
            message.delivery == Delivery.sent ? Icons.done : Icons.done_all,
            key: Key('tick-${message.delivery.name}'),
            size: 15,
            color: message.delivery == Delivery.read ? readTick : color.withValues(alpha: 0.65),
          ),
        ],
      ],
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.message, required this.fg});

  final Message message;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message.text, style: TextStyle(color: fg, fontSize: 15, height: 1.3)),
        const SizedBox(height: 2),
        _Meta(message: message, color: fg),
      ],
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.message, required this.maxWidth});

  final Message message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final bytes = message.imageBytes;
    if (bytes == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ImageViewer(bytes: bytes)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.memory(
              bytes,
              width: maxWidth,
              height: maxWidth * 0.75,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: _Meta(message: message, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioBody extends StatelessWidget {
  const _AudioBody({required this.message, required this.fg});

  final Message message;
  final Color fg;

  static const _bars = 28;

  @override
  Widget build(BuildContext context) {
    final store = ChatScope.of(context);
    final playing = store.playingId == message.id;
    final total = message.audioDuration.inMilliseconds;
    final progress = playing && total > 0 ? (store.position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
    final shown = playing ? store.position : message.audioDuration;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: Key('play-${message.id}'),
                tooltip: playing ? 'Pause' : 'Play voice message',
                onPressed: () => store.togglePlay(message),
                icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36, color: fg),
              ),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _bars; i++)
                        Container(
                          width: 3,
                          height: 6 + ((message.id.hashCode.abs() * (i + 3) * 31) % 18).toDouble(),
                          decoration: BoxDecoration(
                            color: i / _bars < progress ? fg : fg.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Text(formatDuration(shown), style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 12)),
              const Spacer(),
              _Meta(message: message, color: fg),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationBody extends StatelessWidget {
  const _LocationBody({required this.message, required this.fg});

  final Message message;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lat = message.latitude ?? 0;
    final lng = message.longitude ?? 0;
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 110),
                    painter: _MapPainter(scheme.surfaceContainerLow, scheme.outlineVariant),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.location_on, color: Color(0xFFE53935), size: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Shared location', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
          Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 12),
          ),
          Align(alignment: Alignment.centerRight, child: _Meta(message: message, color: fg)),
        ],
      ),
    );
  }
}

/// A simple stand-in for a map tile (grid and one road). Swap it for a real map widget.
class _MapPainter extends CustomPainter {
  const _MapPainter(this.background, this.line);

  final Color background;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final road = Paint()
      ..color = line.withValues(alpha: 0.9)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.2, size.width, size.height * 0.55);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.line != line;
}

class _CallBody extends StatelessWidget {
  const _CallBody({required this.message, required this.fg});

  final Message message;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final info = message.call!;
    final missedByThem = info.missed && message.from == Sender.them;
    final color = missedByThem ? const Color(0xFFE53935) : fg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: fg.withValues(alpha: 0.12),
          child: Icon(info.video ? Icons.videocam : Icons.call, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(callTitle(message), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            Text(
              info.missed ? formatTime(message.at) : '${formatDuration(info.duration)} · ${formatTime(message.at)}',
              style: TextStyle(color: fg.withValues(alpha: 0.65), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
