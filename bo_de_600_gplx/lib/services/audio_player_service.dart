import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playBytes(Uint8List bytes) async {
    try {
      await _player.stop();

      final dir = await getTemporaryDirectory();

      // ✅ dùng 1 file cố định để giảm lag (khỏi tạo file mới liên tục)
      final file = File('${dir.path}/tts.wav');
      await file.writeAsBytes(bytes, flush: true);

      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      print("Play audio error: $e");
      rethrow;
    }
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}
