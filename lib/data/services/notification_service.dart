import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../network/config/app_logger.dart';

class NotificationService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isAvailable = true; // ✅ AJOUTÉ : Tracker la disponibilité
  static bool _isSpeaking = false; // ✅ AJOUTÉ : Tracker l'état de prononciation

  /// Initialiser le service TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (!_isAvailable) return; // ✅ AJOUTÉ : Ne pas réessayer si indisponible

    try {
      AppLogger.info('🔊 [NotificationService] Initialisation TTS');

      // ✅ Callbacks pour tracker l'état
      _tts.setStartHandler(() {
        _isSpeaking = true;
        AppLogger.debug('🎤 [NotificationService] Démarrage prononciation');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('✅ [NotificationService] Prononciation terminée');
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('❌ [NotificationService] Erreur TTS: $msg');
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        AppLogger.debug('⏹️ [NotificationService] Prononciation annulée');
      });

      // ✅ Configuration TTS
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // ✅ Configuration Android
      await _tts.awaitSpeakCompletion(true);

      // ✅ Configuration iOS (si nécessaire)
      try {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
        AppLogger.debug('✅ [NotificationService] Configuration iOS réussie');
      } catch (e) {
        AppLogger.warning('⚠️ [NotificationService] Config iOS non applicable (Android ou erreur)');
      }

      // Vérifier les langues disponibles
      final languages = await _tts.getLanguages;
      AppLogger.debug('   - Langues disponibles: $languages');

      // ✅ Vérifier si le français est disponible
      final isLanguageAvailable = await _tts.isLanguageAvailable('fr-FR');
      AppLogger.debug('   - Français disponible: $isLanguageAvailable');

      if (!isLanguageAvailable) {
        AppLogger.warning('⚠️ [NotificationService] Français non disponible, utilisation langue par défaut');
        // ✅ Fallback en anglais
        await _tts.setLanguage('en-US');
      }

      _isInitialized = true;
      AppLogger.info('✅ [NotificationService] TTS initialisé');
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur initialisation TTS', e);
      _isAvailable = false; // ✅ AJOUTÉ : Marquer comme indisponible
      _isInitialized = false;
    }
  }

  /// Annoncer une nouvelle course
  static Future<void> announceNewOrder({
    required String orderNumber,
    required String customerName,
    required bool isExpress,
  }) async {
    try {
      AppLogger.info('📢 [NotificationService] Annonce nouvelle course');

      // 1. ✅ Jouer un son système
      await playNotificationSound();

      // 2. ✅ Vibrer
      await vibrate();

      // 3. ✅ Annoncer vocalement avec délai plus long
      await Future.delayed(const Duration(milliseconds: 1000));

      final message = isExpress
          ? 'Nouvelle course express ! Commande $orderNumber pour $customerName'
          : 'Nouvelle course ! Commande $orderNumber pour $customerName';

      await speak(message);
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur annonce', e);
    }
  }

  /// Prononcer un texte
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      AppLogger.warning('⚠️ [NotificationService] Texte vide ignoré');
      return;
    }

    if (!_isAvailable) {
      AppLogger.warning('⚠️ [NotificationService] TTS non disponible, texte: $text');
      return;
    }

    try {
      if (!_isInitialized) await initialize();

      if (!_isInitialized) {
        AppLogger.error('❌ [NotificationService] TTS non initialisé après tentative');
        return;
      }

      AppLogger.info('🗣️ [NotificationService] Prononce: "$text"');

      // ✅ Arrêter toute prononciation en cours
      if (_isSpeaking) {
        AppLogger.warning('⚠️ [NotificationService] TTS déjà en cours, arrêt...');
        await _tts.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final result = await _tts.speak(text);

      if (result == 1) {
        AppLogger.debug('✅ [NotificationService] Commande speak envoyée');
      } else {
        AppLogger.error('❌ [NotificationService] Échec speak, code: $result');
      }
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur TTS speak', e);
      _isAvailable = false; // ✅ AJOUTÉ : Marquer comme indisponible en cas d'erreur
      _isSpeaking = false;
    }
  }

  /// Arrêter la voix
  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false; // ✅ AJOUTÉ : Mettre à jour l'état
      AppLogger.debug('⏹️ [NotificationService] Arrêt prononciation');
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur TTS stop', e);
      _isSpeaking = false;
    }
  }

  /// ✅ Jouer un son système (ne nécessite pas de fichier)
  static Future<void> playNotificationSound() async {
    try {
      AppLogger.info('🔔 [NotificationService] Lecture son système');

      // ✅ Jouer plusieurs fois pour être sûr d'entendre
      await SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 200));
      await SystemSound.play(SystemSoundType.alert);

      AppLogger.info('✅ [NotificationService] Son joué');
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur son système', e);
    }
  }

  /// Vibrer le téléphone
  static Future<void> vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        AppLogger.info('📳 [NotificationService] Vibration');
        // Pattern: vibrer 500ms, pause 200ms, vibrer 500ms
        await Vibration.vibrate(pattern: [0, 500, 200, 500]);
      } else {
        AppLogger.warning('⚠️ [NotificationService] Pas de vibreur disponible');
      }
    } catch (e) {
      AppLogger.error('❌ [NotificationService] Erreur vibration', e);
    }
  }

  /// Annoncer le statut de la course
  static Future<void> announceOrderStatus(String status) async {
    final messages = {
      'accepted': 'Course acceptée',
      'picked': 'Colis récupéré',
      'delivering': 'Livraison en cours',
      'delivered': 'Livraison terminée',
      'cancelled': 'Course annulée',
    };

    final message = messages[status] ?? status;

    // ✅ Son + Voix
    await playNotificationSound();
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(message);
  }

  /// Annoncer la distance/durée
  static Future<void> announceRoute({
    required String distance,
    required String duration,
  }) async {
    await speak('Distance: $distance. Durée estimée: $duration');
  }

  /// ✅ NOUVEAU : Vérifier si le TTS est en train de parler
  static bool get isSpeaking => _isSpeaking;

  /// ✅ NOUVEAU : Vérifier si le TTS est disponible
  static bool get isAvailable => _isAvailable;

  /// ✅ NOUVEAU : Réinitialiser le service
  static Future<void> reset() async {
    AppLogger.info('🔄 [NotificationService] Réinitialisation');
    await dispose();
    _isAvailable = true;
    _isInitialized = false;
    await initialize();
  }

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    try {
      await _tts.stop();

      // ✅ Nettoyer les callbacks
      _tts.setStartHandler(() {});
      _tts.setCompletionHandler(() {});
      _tts.setErrorHandler((msg) {});
      _tts.setCancelHandler(() {});

      _isInitialized = false;
      _isSpeaking = false;
      AppLogger.info('🗑️ [NotificationService] Ressources nettoyées');
    } catch (e) {
      AppLogger.warning('⚠️ [NotificationService] Erreur dispose (ignorée): $e');
    }
  }
}