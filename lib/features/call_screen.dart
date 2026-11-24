import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../core/widgets.dart';
import '../data/chat_store.dart';

/// Opens the call screen for a conversation.
///
/// This is a UI demo: the call "connects" after a short delay and runs a timer.
/// To make real calls, plug a WebRTC or call SDK into [CallScreen] (see the README).
Future<void> startCall(BuildContext context, String conversationId, {required bool video}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CallScreen(conversationId: conversationId, video: video),
    ),
  );
}

enum _Phase { calling, connected }

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.conversationId, required this.video});

  final String conversationId;
  final bool video;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  _Phase _phase = _Phase.calling;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _speaker = false;
  bool _cameraOff = false;
  bool _started = false;
  bool _ended = false;
  Timer? _connectTimer;
  Timer? _tickTimer;
  late ChatStore _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = ChatScope.of(context);
    if (_started) return;
    _started = true;
    _connectTimer = Timer(_store.callConnectDelay, _connect);
  }

  void _connect() {
    setState(() => _phase = _Phase.connected);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _connectTimer?.cancel();
    _tickTimer?.cancel();
    _store.logCall(
      widget.conversationId,
      video: widget.video,
      duration: _elapsed,
      missed: _phase == _Phase.calling,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _store.byId(widget.conversationId);
    final status = _phase == _Phase.calling
        ? (widget.video ? 'Video calling…' : 'Calling…')
        : formatDuration(_elapsed);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _end();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(c.color.withValues(alpha: widget.video ? 0.55 : 0.35), const Color(0xFF0B141A)),
                    const Color(0xFF0B141A),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    c.name,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(status, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  Expanded(
                    child: Center(
                      child: ChatAvatar(name: c.name, color: c.color, radius: widget.video ? 72 : 80),
                    ),
                  ),
                  _Controls(
                    video: widget.video,
                    muted: _muted,
                    speaker: _speaker,
                    cameraOff: _cameraOff,
                    onMute: () => setState(() => _muted = !_muted),
                    onSpeaker: () => setState(() => _speaker = !_speaker),
                    onCamera: () => setState(() => _cameraOff = !_cameraOff),
                    onEnd: _end,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            if (widget.video)
              Positioned(
                top: 0,
                right: 16,
                child: SafeArea(
                  child: Container(
                    key: const Key('self-view'),
                    width: 104,
                    height: 144,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      _cameraOff ? Icons.videocam_off_outlined : Icons.person_outline,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.video,
    required this.muted,
    required this.speaker,
    required this.cameraOff,
    required this.onMute,
    required this.onSpeaker,
    required this.onCamera,
    required this.onEnd,
  });

  final bool video;
  final bool muted;
  final bool speaker;
  final bool cameraOff;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          tooltip: speaker ? 'Speaker off' : 'Speaker on',
          icon: speaker ? Icons.volume_up : Icons.volume_down_outlined,
          active: speaker,
          onTap: onSpeaker,
        ),
        if (video)
          _RoundButton(
            tooltip: cameraOff ? 'Camera on' : 'Camera off',
            icon: cameraOff ? Icons.videocam_off : Icons.videocam_outlined,
            active: cameraOff,
            onTap: onCamera,
          ),
        _RoundButton(
          tooltip: muted ? 'Unmute' : 'Mute',
          icon: muted ? Icons.mic_off : Icons.mic_none,
          active: muted,
          onTap: onMute,
        ),
        _RoundButton(
          tooltip: 'End call',
          icon: Icons.call_end,
          background: const Color(0xFFE53935),
          active: true,
          onTap: onEnd,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.background,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (active ? Colors.white : Colors.white12);
    final fg = background != null || !active ? Colors.white : Colors.black87;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(icon, color: fg, size: 28),
          ),
        ),
      ),
    );
  }
}
