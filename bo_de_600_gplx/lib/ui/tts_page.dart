import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:bo_de_600_gplx/services/audio_player_service.dart';
import 'package:bo_de_600_gplx/services/tts_service.dart';

class TtsHelper {
  TtsHelper({required VoidCallback onStateChanged})
      : _onStateChanged = onStateChanged;

  final VoidCallback _onStateChanged;

  bool _loading = false;
  String? _key; // key nào đang speak (q / a0 / a1 ...)
  int _reqId = 0;

  // cache client để giảm lag
  final Map<String, Uint8List> _cache = {};

  bool get isLoading => _loading;
  String? get loadingKey => _key;

  /// đọc text (giống hệt logic trang 20 câu)
  Future<void> speak(String text, {String key = "tts"}) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final int myId = ++_reqId;

    _loading = true;
    _key = key;
    _onStateChanged();

    try {
      // ✅ cache
      final cached = _cache[t];
      if (cached != null) {
        if (myId != _reqId) return;
        await AudioPlayerService.playBytes(cached);
        return;
      }

      final bytes = await TtsService.synthesize(t);
      if (myId != _reqId) return;

      if (bytes != null && bytes.isNotEmpty) {
        _cache[t] = bytes;
        await AudioPlayerService.playBytes(bytes);
      }
    } finally {
      if (myId == _reqId) {
        _loading = false;
        _key = null;
        _onStateChanged();
      }
    }
  }

  /// dừng đọc + huỷ request cũ
  Future<void> stop() async {
    _reqId++;
    await AudioPlayerService.stop();
    _loading = false;
    _key = null;
    _onStateChanged();
  }

  /// Widget nút loa dùng chung (tự hiện loading)
  Widget buildSpeakButton({
    required String text,
    String key = "q",
    String tooltip = "Đọc",
    IconData icon = Icons.volume_up,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: _loading ? null : () => speak(text, key: key),
      icon: (_loading && _key == key)
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: color),
    );
  }

  /// gọi ở dispose() của trang
  Future<void> dispose() async {
    await stop();
  }
}
