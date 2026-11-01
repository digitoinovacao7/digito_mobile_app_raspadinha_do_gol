import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Helper de áudio seguro para evitar crashes por MissingPluginException no Web ou falta de suporte.
class SafeAudioPlayer {
  AudioPlayer? _player;

  void play(String soundPath, {double volume = 1.0}) {
    try {
      _player ??= AudioPlayer();
      _player?.play(AssetSource(soundPath), volume: volume).catchError((e) {
        debugPrint('Erro ao reproduzir áudio ($soundPath): $e');
      });
    } catch (e) {
      debugPrint('Exceção ao inicializar/tocar áudio ($soundPath): $e');
    }
  }

  void dispose() {
    try {
      _player?.dispose();
      _player = null;
    } catch (e) {
      debugPrint('Erro ao descartar áudio: $e');
    }
  }
}
