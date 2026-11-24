import 'dart:typed_data';

enum ImageOrigin { gallery, camera }

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Everything the chat needs from the device: camera, gallery, microphone,
/// audio playback and GPS. The app uses [DeviceMediaService]; tests use a fake.
abstract class MediaService {
  /// Picks a photo. Returns null when the user cancels.
  Future<Uint8List?> pickImage(ImageOrigin origin);

  /// Starts recording a voice message. Returns false without microphone permission.
  Future<bool> startRecording();

  /// Stops and returns the recorded file path (or blob URL on the web).
  Future<String?> stopRecording();

  Future<void> cancelRecording();

  /// Current position, or null when location is off or denied.
  Future<GeoPoint?> currentLocation();

  Future<void> play(String source);

  Future<void> pause();

  Stream<Duration> get positionStream;

  Stream<void> get completeStream;

  void dispose();
}
