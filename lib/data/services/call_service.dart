import 'package:url_launcher/url_launcher.dart';
import '../../network/config/app_logger.dart';

class CallService {
  /// Lancer un appel téléphonique
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      AppLogger.warning('⚠️ [CallService] Numéro de téléphone vide');
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleanNumber);

    AppLogger.info('📞 [CallService] Tentative d\'appel vers: $cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          AppLogger.info('✅ [CallService] Appel lancé avec succès');
          return true;
        } else {
          AppLogger.error('❌ [CallService] Impossible de lancer l\'appel');
          return false;
        }
      } else {
        AppLogger.error('❌ [CallService] Application téléphone non disponible');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ [CallService] Erreur lors de l\'appel', e);
      return false;
    }
  }

  /// ✅ NOUVELLE VERSION : Ouvrir WhatsApp avec plusieurs méthodes de fallback
  static Future<bool> openWhatsApp(String phoneNumber, {String? message}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      AppLogger.warning('⚠️ [CallService] Numéro WhatsApp vide');
      return false;
    }

    // Encoder le message pour l'URL
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';

    // ✅ MÉTHODE 1 : Essayer l'URL directe de l'app WhatsApp (préféré)
    final whatsappAppUrl = Uri.parse(
      'whatsapp://send?phone=$cleanNumber${message != null ? '&text=$encodedMessage' : ''}',
    );

    AppLogger.info('📱 [CallService] Méthode 1 - Tentative whatsapp://');
    AppLogger.debug('   URL: $whatsappAppUrl');

    try {
      if (await canLaunchUrl(whatsappAppUrl)) {
        final launched = await launchUrl(
          whatsappAppUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          AppLogger.info('✅ [CallService] WhatsApp ouvert (méthode 1)');
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('⚠️ [CallService] Méthode 1 échouée: $e');
    }

    // ✅ MÉTHODE 2 : Essayer via wa.me (Web/App)
    final waUrl = Uri.parse(
      'https://wa.me/$cleanNumber${message != null ? '?text=$encodedMessage' : ''}',
    );

    AppLogger.info('📱 [CallService] Méthode 2 - Tentative https://wa.me/');
    AppLogger.debug('   URL: $waUrl');

    try {
      if (await canLaunchUrl(waUrl)) {
        final launched = await launchUrl(
          waUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          AppLogger.info('✅ [CallService] WhatsApp ouvert (méthode 2)');
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('⚠️ [CallService] Méthode 2 échouée: $e');
    }

    // ✅ MÉTHODE 3 : Essayer l'API WhatsApp
    final apiUrl = Uri.parse(
      'https://api.whatsapp.com/send?phone=$cleanNumber${message != null ? '&text=$encodedMessage' : ''}',
    );

    AppLogger.info('📱 [CallService] Méthode 3 - Tentative https://api.whatsapp.com/');
    AppLogger.debug('   URL: $apiUrl');

    try {
      if (await canLaunchUrl(apiUrl)) {
        final launched = await launchUrl(
          apiUrl,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          AppLogger.info('✅ [CallService] WhatsApp ouvert (méthode 3)');
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('⚠️ [CallService] Méthode 3 échouée: $e');
    }

    // ❌ Toutes les méthodes ont échoué
    AppLogger.error('❌ [CallService] Impossible d\'ouvrir WhatsApp - Toutes les méthodes ont échoué');
    return false;
  }

  /// Envoyer un SMS
  static Future<bool> sendSMS(String phoneNumber, {String? message}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      AppLogger.warning('⚠️ [CallService] Numéro SMS vide');
      return false;
    }

    final uri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: message != null ? {'body': message} : null,
    );

    AppLogger.info('💬 [CallService] Envoi SMS vers: $cleanNumber');

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri);

        if (launched) {
          AppLogger.info('✅ [CallService] SMS lancé');
          return true;
        } else {
          AppLogger.error('❌ [CallService] Impossible d\'ouvrir SMS');
          return false;
        }
      } else {
        AppLogger.error('❌ [CallService] Application SMS non disponible');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ [CallService] Erreur SMS', e);
      return false;
    }
  }

  /// Formater un numéro pour l'affichage
  static String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Format ivoirien : +225 XX XX XX XX XX
    if (cleanNumber.startsWith('225') && cleanNumber.length == 12) {
      return '+225 ${cleanNumber.substring(3, 5)} ${cleanNumber.substring(5, 7)} ${cleanNumber.substring(7, 9)} ${cleanNumber.substring(9, 11)} ${cleanNumber.substring(11)}';
    }
    // Avec + au début
    else if (cleanNumber.startsWith('+225') && cleanNumber.length == 13) {
      return '+225 ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8, 10)} ${cleanNumber.substring(10, 12)} ${cleanNumber.substring(12)}';
    }
    // Format local : 0X XX XX XX XX
    else if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 4)} ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8)}';
    }

    return phoneNumber;
  }

  /// Vérifier si un numéro est valide
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanNumber.length >= 8 && RegExp(r'^[\d+]+$').hasMatch(cleanNumber);
  }

  /// ✅ NOUVEAU : Vérifier si WhatsApp est installé
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final whatsappUrl = Uri.parse('whatsapp://send?phone=0000000000');
      final isInstalled = await canLaunchUrl(whatsappUrl);

      AppLogger.info(
          isInstalled
              ? '✅ [CallService] WhatsApp est installé'
              : '⚠️ [CallService] WhatsApp n\'est pas installé'
      );

      return isInstalled;
    } catch (e) {
      AppLogger.error('❌ [CallService] Erreur vérification WhatsApp', e);
      return false;
    }
  }
}