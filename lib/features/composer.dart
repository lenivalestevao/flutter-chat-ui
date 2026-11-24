import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/scope.dart';
import '../services/media_service.dart';

/// Message bar: attach (gallery, camera, location), text field, and a mic
/// button that turns into send when there is text. Hold-free voice recording:
/// tap the mic, then tap send (or the bin to cancel).
class Composer extends StatefulWidget {
  const Composer({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  Timer? _ticker;
  bool _recording = false;
  Duration _elapsed = Duration.zero;

  /// Recordings shorter than this are treated as accidental taps.
  static const minRecording = Duration(milliseconds: 500);

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ChatScope.of(context).send(widget.conversationId, text);
    _controller.clear();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageOrigin origin) async {
    final store = ChatScope.of(context);
    final bytes = await store.media.pickImage(origin);
    if (bytes != null) store.sendImage(widget.conversationId, bytes);
  }

  Future<void> _shareLocation() async {
    final store = ChatScope.of(context);
    final point = await store.media.currentLocation();
    if (!mounted) return;
    if (point == null) {
      _toast('Location is turned off or not allowed.');
      return;
    }
    store.sendLocation(widget.conversationId, point.latitude, point.longitude);
  }

  void _openAttachMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget option(Key key, IconData icon, String label, Color color, VoidCallback onTap) {
          return InkWell(
            key: key,
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(sheet).pop();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: color, child: Icon(icon, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(label),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                option(const Key('attach-gallery'), Icons.photo_library, 'Gallery', const Color(0xFF7C5CFF),
                    () => _pick(ImageOrigin.gallery)),
                option(const Key('attach-camera'), Icons.photo_camera, 'Camera', const Color(0xFFEC4899),
                    () => _pick(ImageOrigin.camera)),
                option(const Key('attach-location'), Icons.location_on, 'Location', const Color(0xFF0EA5A4), _shareLocation),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    final store = ChatScope.of(context);
    final ok = await store.media.startRecording();
    if (!mounted) return;
    if (!ok) {
      _toast('Microphone permission is needed to record.');
      return;
    }
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      setState(() => _elapsed += const Duration(milliseconds: 250));
    });
  }

  Future<void> _finishRecording({required bool send}) async {
    final store = ChatScope.of(context);
    final id = widget.conversationId;
    final length = _elapsed;
    _ticker?.cancel();
    setState(() => _recording = false);
    if (!send || length < minRecording) {
      await store.media.cancelRecording();
      return;
    }
    final path = await store.media.stopRecording();
    if (path != null) store.sendAudio(id, path, length);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: _recording ? _recordingBar(scheme) : _typingBar(scheme),
        ),
      ),
    );
  }

  Widget _typingBar(ColorScheme scheme) {
    return Row(
      children: [
        IconButton(
          key: const Key('attach'),
          tooltip: 'Attach',
          onPressed: _openAttachMenu,
          icon: const Icon(Icons.add_circle_outline),
        ),
        Expanded(
          child: TextField(
            key: const Key('composer'),
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Message',
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return IconButton.filled(
              key: Key(hasText ? 'send' : 'mic'),
              tooltip: hasText ? 'Send message' : 'Record voice message',
              onPressed: hasText ? _submit : _startRecording,
              icon: Icon(hasText ? Icons.send_rounded : Icons.mic),
            );
          },
        ),
      ],
    );
  }

  Widget _recordingBar(ColorScheme scheme) {
    return Row(
      key: const Key('recording'),
      children: [
        IconButton(
          key: const Key('cancel-recording'),
          tooltip: 'Discard recording',
          onPressed: () => _finishRecording(send: false),
          icon: Icon(Icons.delete_outline, color: scheme.error),
        ),
        const Icon(Icons.fiber_manual_record, color: Color(0xFFE53935), size: 14),
        const SizedBox(width: 8),
        Text(formatDuration(_elapsed), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('Recording…', style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(width: 12),
        IconButton.filled(
          key: const Key('send-recording'),
          tooltip: 'Send voice message',
          onPressed: () => _finishRecording(send: true),
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}
