import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'media_service.dart';

/// Real implementation on top of image_picker, record, audioplayers and geolocator.
class DeviceMediaService implements MediaService {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  @override
  Future<Uint8List?> pickImage(ImageOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == ImageOrigin.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;
    var path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    await _recorder.start(const RecordConfig(), path: path);
    return true;
  }

  @override
  Future<String?> stopRecording() => _recorder.stop();

  @override
  Future<void> cancelRecording() => _recorder.cancel();

  @override
  Future<GeoPoint?> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GeoPoint(p.latitude, p.longitude);
  }

  @override
  Future<void> play(String source) async {
    await _player.stop();
    await _player.play(kIsWeb ? UrlSource(source) : DeviceFileSource(source));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  @override
  Stream<void> get completeStream => _player.onPlayerComplete;

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
  }
}
