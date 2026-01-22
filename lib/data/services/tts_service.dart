import 'package:flutter_tts/flutter_tts.dart';
import '../../network/config/app_logger.dart';
import '../models/navigation/navigation_step.dart';

class TtsService {
  static FlutterTts? _flutterTts;
  static bool _isInitialized = false;
  static bool _isAvailable = true;
  static bool _isSpeaking = false;
  static String? _lastSpokenText;
  static DateTime? _lastSpeakTime;

  /// Initialiser le service TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!_isAvailable) return;

    try {
      AppLogger.info('🔊 [TtsService] Initialisation TTS');

      _flutterTts = FlutterTts();

      // ✅ Callbacks pour tracker l'état
      _flutterTts?.setStartHandler(() {
        _isSpeaking = true;
        AppLogger.debug('🎤 [TtsService] Démarrage prononciation');
      });

      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('✅ [TtsService] Prononciation terminée');
      });

      _flutterTts?.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('❌ [TtsService] Erreur TTS: $msg');
      });

      _flutterTts?.setCancelHandler(() {
        _isSpeaking = false;
        AppLogger.debug('⏹️ [TtsService] Prononciation annulée');
      });

      // ✅ Configuration Android
      await _flutterTts?.setLanguage('fr-FR');
      await _flutterTts?.setSpeechRate(0.5); // Vitesse normale
      await _flutterTts?.setVolume(1.0); // Volume maximum
      await _flutterTts?.setPitch(1.0); // Ton normal

      // ✅ Vérifier si la langue française est disponible
      final isLanguageAvailable = await _flutterTts?.isLanguageAvailable('fr-FR') ?? false;
      if (!isLanguageAvailable) {
        AppLogger.warning('⚠️ [TtsService] Français non disponible, utilisation langue par défaut');
        await _flutterTts?.setLanguage('en-US');
      }

      // ✅ Configuration iOS (avec gestion d'erreur)
      if (_flutterTts != null) {
        try {
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
          AppLogger.debug('✅ [TtsService] Configuration iOS réussie');
        } catch (e) {
          AppLogger.warning('⚠️ [TtsService] Erreur config iOS (non critique): $e');
        }
      }

      // ✅ IMPORTANT : Attendre que le speak soit vraiment prêt
      await _flutterTts?.awaitSpeakCompletion(true);

      _isInitialized = true;
      AppLogger.info('✅ [TtsService] TTS initialisé avec succès');
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur initialisation', e);
      _isAvailable = false;
      _isInitialized = false;
      _flutterTts = null;
    }
  }

  /// ✅ NOUVEAU : Annoncer une instruction de navigation avec distance
  static Future<void> announceNavigationStep(
      NavigationStep step,
      double distanceToStep,
      ) async {
    if (!_isAvailable) return;

    try {
      await initialize();

      if (_flutterTts == null || !_isInitialized) {
        AppLogger.error('❌ [TtsService] TTS non initialisé');
        return;
      }

      // Obtenir l'instruction vocale enrichie
      final instruction = step.getVoiceInstruction(distanceToStep);

      // Éviter de répéter la même instruction trop rapidement
      if (_shouldSkipAnnouncement(instruction)) {
        AppLogger.debug('⏭️ [TtsService] Instruction ignorée (trop récente): $instruction');
        return;
      }

      await speak(instruction);

      // Mémoriser cette annonce
      _lastSpokenText = instruction;
      _lastSpeakTime = DateTime.now();
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur annonce instruction', e);
    }
  }

  /// ✅ NOUVEAU : Vérifier si on doit ignorer l'annonce (éviter les répétitions)
  static bool _shouldSkipAnnouncement(String text) {
    // Si c'est la même instruction
    if (_lastSpokenText == text) {
      // Et qu'elle a été prononcée il y a moins de 5 secondes
      if (_lastSpeakTime != null &&
          DateTime.now().difference(_lastSpeakTime!).inSeconds < 5) {
        return true;
      }
    }
    return false;
  }

  /// Prononcer un texte
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      AppLogger.warning('⚠️ [TtsService] Texte vide ignoré');
      return;
    }

    if (!_isAvailable) {
      AppLogger.warning('⚠️ [TtsService] TTS non disponible, texte: $text');
      return;
    }

    try {
      await initialize();

      if (_flutterTts == null || !_isInitialized) {
        AppLogger.error('❌ [TtsService] TTS non initialisé');
        return;
      }

      // ✅ Arrêter toute prononciation en cours
      if (_isSpeaking) {
        AppLogger.debug('⏹️ [TtsService] Arrêt prononciation précédente');
        await stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      AppLogger.info('🔊 [TtsService] Prononciation: "$text"');

      // ✅ Prononcer et attendre la fin
      final result = await _flutterTts!.speak(text);

      if (result == 1) {
        AppLogger.debug('✅ [TtsService] Commande speak envoyée');
      } else {
        AppLogger.error('❌ [TtsService] Échec speak, code: $result');
      }
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur prononciation', e);
      _isAvailable = false;
      _isSpeaking = false;
    }
  }

  /// ✅ NOUVEAU : Annoncer avec une pause avant
  static Future<void> speakWithPause(String text, {Duration pause = const Duration(milliseconds: 500)}) async {
    await Future.delayed(pause);
    await speak(text);
  }

  /// ✅ NOUVEAU : Annoncer plusieurs textes en séquence
  static Future<void> speakSequence(List<String> texts, {Duration pauseBetween = const Duration(seconds: 1)}) async {
    for (int i = 0; i < texts.length; i++) {
      await speak(texts[i]);

      if (i < texts.length - 1) {
        // Attendre la fin de la prononciation avant de continuer
        await awaitCompletion();
        await Future.delayed(pauseBetween);
      }
    }
  }

  /// ✅ NOUVEAU : Annoncer un message d'urgence (coupe tout)
  static Future<void> speakUrgent(String text) async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 100));
    await speak(text);
  }

  /// ✅ NOUVEAU : Changer la vitesse de prononciation
  static Future<void> setSpeechRate(double rate) async {
    // rate: 0.0 à 1.0 (0.5 = normal, 1.0 = rapide, 0.0 = lent)
    try {
      await initialize();
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(rate.clamp(0.0, 1.0));
        AppLogger.info('🔊 [TtsService] Vitesse changée: $rate');
      }
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur setSpeechRate', e);
    }
  }

  /// ✅ NOUVEAU : Changer le volume
  static Future<void> setVolume(double volume) async {
    // volume: 0.0 à 1.0
    try {
      await initialize();
      if (_flutterTts != null) {
        await _flutterTts!.setVolume(volume.clamp(0.0, 1.0));
        AppLogger.info('🔊 [TtsService] Volume changé: $volume');
      }
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur setVolume', e);
    }
  }

  /// Arrêter la prononciation
  static Future<void> stop() async {
    if (!_isAvailable || _flutterTts == null) return;

    try {
      await _flutterTts!.stop();
      _isSpeaking = false;
      AppLogger.debug('⏹️ [TtsService] Arrêt prononciation');
    } catch (e) {
      AppLogger.warning('⚠️ [TtsService] Erreur stop (ignorée): $e');
      _isSpeaking = false;
    }
  }

  /// Vérifier si en cours de prononciation
  static bool get isSpeaking => _isSpeaking;

  /// Attendre la fin de la prononciation en cours
  static Future<void> awaitCompletion() async {
    if (!_isSpeaking || _flutterTts == null) return;

    try {
      // Attendre max 10 secondes
      int attempts = 0;
      while (_isSpeaking && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    } catch (e) {
      AppLogger.warning('⚠️ [TtsService] Erreur awaitCompletion: $e');
    }
  }

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    try {
      await stop();

      _flutterTts?.setStartHandler(() {});
      _flutterTts?.setCompletionHandler(() {});
      _flutterTts?.setErrorHandler((msg) {});
      _flutterTts?.setCancelHandler(() {});

      _flutterTts = null;
      _isInitialized = false;
      _isSpeaking = false;
      _lastSpokenText = null;
      _lastSpeakTime = null;

      AppLogger.info('🗑️ [TtsService] Ressources nettoyées');
    } catch (e) {
      AppLogger.warning('⚠️ [TtsService] Erreur dispose (ignorée): $e');
    }
  }

  /// Vérifier la disponibilité
  static bool get isAvailable => _isAvailable;

  /// Réinitialiser en cas de problème
  static Future<void> reset() async {
    AppLogger.info('🔄 [TtsService] Réinitialisation');
    await dispose();
    _isAvailable = true;
    _isInitialized = false;
    await initialize();
  }

  /// Obtenir les langues disponibles
  static Future<List<String>> getAvailableLanguages() async {
    try {
      await initialize();
      if (_flutterTts == null) return [];

      final languages = await _flutterTts!.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur getLanguages', e);
      return [];
    }
  }

  /// Définir la langue
  static Future<bool> setLanguage(String language) async {
    try {
      await initialize();
      if (_flutterTts == null) return false;

      final isAvailable = await _flutterTts!.isLanguageAvailable(language);
      if (!isAvailable) {
        AppLogger.warning('⚠️ [TtsService] Langue $language non disponible');
        return false;
      }

      await _flutterTts!.setLanguage(language);
      AppLogger.info('✅ [TtsService] Langue changée: $language');
      return true;
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur setLanguage', e);
      return false;
    }
  }

  /// ✅ NOUVEAU : Obtenir un résumé des paramètres actuels
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      await initialize();
      if (_flutterTts == null) return {};

      final voices = await _flutterTts!.getVoices;
      final languages = await _flutterTts!.getLanguages;

      return {
        'isInitialized': _isInitialized,
        'isAvailable': _isAvailable,
        'isSpeaking': _isSpeaking,
        'voices': voices,
        'languages': languages,
      };
    } catch (e) {
      AppLogger.error('❌ [TtsService] Erreur getSettings', e);
      return {};
    }
  }
}