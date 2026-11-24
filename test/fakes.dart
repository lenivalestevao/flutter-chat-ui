import 'dart:async';
import 'dart:typed_data';

import 'package:chatly_chat/services/media_service.dart';

/// 1x1 transparent PNG.
final tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// In-memory [MediaService] so tests never touch a camera, microphone or GPS.
class FakeMediaService implements MediaService {
  Uint8List? image = tinyPng;
  GeoPoint? location = const GeoPoint(-23.55052, -46.63331);
  bool micAllowed = true;
  String recordingPath = '/tmp/voice_test.m4a';

  int recordingsStarted = 0;
  int recordingsCancelled = 0;
  String? played;
  int pauses = 0;
  bool disposed = false;

  final _position = StreamController<Duration>.broadcast();
  final _complete = StreamController<void>.broadcast();

  void finishPlayback() => _complete.add(null);

  @override
  Future<Uint8List?> pickImage(ImageOrigin origin) async => image;

  @override
  Future<bool> startRecording() async {
    if (!micAllowed) return false;
    recordingsStarted++;
    return true;
  }

  @override
  Future<String?> stopRecording() async => recordingPath;

  @override
  Future<void> cancelRecording() async => recordingsCancelled++;

  @override
  Future<GeoPoint?> currentLocation() async => location;

  @override
  Future<void> play(String source) async => played = source;

  @override
  Future<void> pause() async => pauses++;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<void> get completeStream => _complete.stream;

  @override
  void dispose() {
    disposed = true;
    unawaited(_position.close());
    unawaited(_complete.close());
  }
}
