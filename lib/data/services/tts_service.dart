import 'package:flutter_tts/flutter_tts.dart';
import '../../network/config/app_logger.dart';

class TtsService {
  static FlutterTts? _flutterTts;
  static bool _isInitialized = false;
  static bool _isAvailable = true;

  /// Initialiser le service TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!_isAvailable) return;

    try {
      AppLogger.info('🔊 [TtsService] Initialisation TTS');

      _flutterTts = FlutterTts();

      // Configuration pour Android
      await _flutterTts?.setLanguage('fr-FR');
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);

      // Configuration iOS
      if (_flutterTts != null) {
        await _flutterTts!.setSharedInstance(true);
        await _flutterTts!.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _isInitialized = true;
      AppLogger.info('✅ [TtsService] TTS initialisé');
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur initialisation', e);
      _isAvailable = false;
      _isInitialized = false;
      _flutterTts = null;
    }
  }

  /// Prononcer un texte
  static Future<void> speak(String text) async {
    if (!_isAvailable) {
      AppLogger.warning('⚠️ [TtsService] TTS non disponible, texte: $text');
      return;
    }

    try {
      await initialize();
      if (_flutterTts != null && _isInitialized) {
        AppLogger.debug('🔊 [TtsService] Prononciation: $text');
        await _flutterTts!.speak(text);
      }
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur prononciation', e);
      _isAvailable = false;
    }
  }

  /// Arrêter la prononciation
  static Future<void> stop() async {
    if (!_isAvailable || _flutterTts == null) return;

    try {
      await _flutterTts!.stop();
    } catch (e) {
      AppLogger.warning('⚠️ [TtsService] Erreur stop (ignorée)');
      // On ignore l'erreur car ce n'est pas critique
    }
  }

  /// Vérifier si en cours de prononciation
  static Future<bool> isSpeaking() async {
    if (!_isAvailable || _flutterTts == null) return false;

    try {
      return await _flutterTts!.awaitSpeakCompletion(true);
    } catch (e) {
      return false;
    }
  }

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    try {
      await stop();
      _flutterTts = null;
      _isInitialized = false;
    } catch (e) {
      AppLogger.warning('⚠️ [TtsService] Erreur dispose (ignorée)');
    }
  }

  /// Vérifier la disponibilité
  static bool get isAvailable => _isAvailable;
}