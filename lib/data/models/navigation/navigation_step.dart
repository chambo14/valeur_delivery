// models/navigation/navigation_step.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationStep {
  final LatLng startLocation;
  final LatLng endLocation;
  final String instruction;
  final String distance;
  final int distanceValue; // en mètres
  final String duration;
  final int durationValue; // en secondes
  final String? maneuver; // turn-left, turn-right, etc.
  final String? streetName; // ✅ NOUVEAU : Nom de la rue extraite

  NavigationStep({
    required this.startLocation,
    required this.endLocation,
    required this.instruction,
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    this.maneuver,
    this.streetName, // ✅ NOUVEAU
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    // Parsing sécurisé des coordonnées
    final startLoc = json['start_location'] as Map<String, dynamic>?;
    final endLoc = json['end_location'] as Map<String, dynamic>?;
    final distanceData = json['distance'] as Map<String, dynamic>?;
    final durationData = json['duration'] as Map<String, dynamic>?;

    // ✅ NOUVEAU : Récupérer l'instruction HTML avant de la nettoyer
    final htmlInstructions = json['html_instructions'] as String? ?? '';

    // ✅ NOUVEAU : Extraire le nom de la rue depuis l'HTML
    final extractedStreetName = _extractStreetName(htmlInstructions);

    return NavigationStep(
      startLocation: LatLng(
        _parseDouble(startLoc?['lat']) ?? 0.0,
        _parseDouble(startLoc?['lng']) ?? 0.0,
      ),
      endLocation: LatLng(
        _parseDouble(endLoc?['lat']) ?? 0.0,
        _parseDouble(endLoc?['lng']) ?? 0.0,
      ),
      instruction: _cleanHtml(htmlInstructions),
      distance: distanceData?['text'] as String? ?? '',
      distanceValue: _parseInt(distanceData?['value']) ?? 0,
      duration: durationData?['text'] as String? ?? '',
      durationValue: _parseInt(durationData?['value']) ?? 0,
      maneuver: json['maneuver'] as String?,
      streetName: extractedStreetName, // ✅ NOUVEAU
    );
  }

  // ✅ NOUVEAU : Extraire le nom de rue depuis l'instruction HTML
  static String? _extractStreetName(String htmlInstruction) {
    if (htmlInstruction.isEmpty) return null;

    // Patterns courants dans les instructions Google Maps
    // Exemples:
    // "Tournez à <b>droite</b> sur <b>Boulevard Houphouët-Boigny</b>"
    // "Continuez sur <b>Rue de la Paix</b>"
    // "Prenez <b>Avenue 14</b>"
    // "Rejoignez <b>Autoroute du Nord</b>"

    final patterns = [
      RegExp(r'sur <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'vers <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'dans <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'prenez <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'rejoignez <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'continuez sur <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'empruntez <b>(.*?)</b>', caseSensitive: false),
      // Patterns en anglais (au cas où)
      RegExp(r'onto <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'on <b>(.*?)</b>', caseSensitive: false),
      RegExp(r'toward <b>(.*?)</b>', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(htmlInstruction);
      if (match != null && match.group(1) != null) {
        final streetName = match.group(1)!.trim();

        // Éviter les directions comme "droite" ou "gauche"
        if (!_isDirection(streetName) && streetName.length > 2) {
          return streetName;
        }
      }
    }

    return null;
  }

  // ✅ NOUVEAU : Vérifier si le texte est une direction plutôt qu'un nom de rue
  static bool _isDirection(String text) {
    final directions = [
      'droite', 'gauche', 'tout droit', 'droit', 'straight',
      'north', 'south', 'east', 'west',
      'nord', 'sud', 'est', 'ouest',
      'left', 'right'
    ];

    final lowerText = text.toLowerCase();
    return directions.any((d) => lowerText == d || lowerText.contains(' $d'));
  }

  // Parser double de manière sécurisée
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Parser int de manière sécurisée
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Nettoyer le HTML des instructions
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  // Vérifier si les coordonnées sont valides
  bool get hasValidStartLocation =>
      startLocation.latitude != 0.0 && startLocation.longitude != 0.0;

  bool get hasValidEndLocation =>
      endLocation.latitude != 0.0 && endLocation.longitude != 0.0;

  bool get isValid => hasValidStartLocation && hasValidEndLocation;

  // Obtenir l'icône selon la manœuvre
  String get maneuverIcon {
    switch (maneuver?.toLowerCase()) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'turn-slight-left':
        return '↖';
      case 'turn-slight-right':
        return '↗';
      case 'turn-sharp-left':
        return '⬅';
      case 'turn-sharp-right':
        return '➡';
      case 'uturn-left':
      case 'uturn-right':
        return '⤴';
      case 'merge':
        return '⇆';
      case 'roundabout-left':
      case 'roundabout-right':
        return '⟲';
      case 'ramp-left':
      case 'ramp-right':
        return '↗';
      case 'straight':
        return '↑';
      case 'fork-left':
        return '↙';
      case 'fork-right':
        return '↘';
      default:
        return '↑';
    }
  }

  // ✅ NOUVEAU : Obtenir une instruction vocale enrichie avec distance
  String getVoiceInstruction(double distanceToStep) {
    final direction = _getDirectionText();
    final distancePhrase = _getDistancePhrase(distanceToStep);

    if (streetName != null && streetName!.isNotEmpty) {
      return '$distancePhrase$direction sur $streetName';
    }

    return '$distancePhrase$direction';
  }

  // ✅ NOUVEAU : Obtenir le texte de direction en français naturel
  String _getDirectionText() {
    if (maneuver == null) return instruction;

    switch (maneuver!.toLowerCase()) {
      case 'turn-left':
        return 'tournez à gauche';
      case 'turn-right':
        return 'tournez à droite';
      case 'turn-slight-left':
        return 'tournez légèrement à gauche';
      case 'turn-slight-right':
        return 'tournez légèrement à droite';
      case 'turn-sharp-left':
        return 'virez fortement à gauche';
      case 'turn-sharp-right':
        return 'virez fortement à droite';
      case 'uturn-left':
      case 'uturn-right':
        return 'faites demi-tour';
      case 'merge':
        return 'rejoignez la voie';
      case 'ramp-left':
        return 'prenez la sortie à gauche';
      case 'ramp-right':
        return 'prenez la sortie à droite';
      case 'fork-left':
        return 'à la fourche, restez à gauche';
      case 'fork-right':
        return 'à la fourche, restez à droite';
      case 'roundabout-left':
      case 'roundabout-right':
        return 'prenez le rond-point';
      case 'straight':
        return 'continuez tout droit';
      case 'keep-left':
        return 'restez sur la gauche';
      case 'keep-right':
        return 'restez sur la droite';
      default:
        return instruction;
    }
  }

  // ✅ NOUVEAU : Obtenir la phrase de distance appropriée
  String _getDistancePhrase(double meters) {
    if (meters < 30) {
      return 'Maintenant, ';
    } else if (meters < 50) {
      return 'Dans quelques mètres, ';
    } else if (meters < 100) {
      return 'Dans ${meters.round()} mètres, ';
    } else if (meters < 300) {
      int rounded = ((meters / 50).round() * 50);
      return 'Dans $rounded mètres, ';
    } else if (meters < 1000) {
      int rounded = ((meters / 100).round() * 100);
      return 'Dans $rounded mètres, ';
    } else {
      double km = meters / 1000;
      if (km < 2) {
        return 'Dans ${km.toStringAsFixed(1).replaceAll('.', ',')} kilomètre, ';
      }
      return 'Dans ${km.toStringAsFixed(1).replaceAll('.', ',')} kilomètres, ';
    }
  }

  // ✅ NOUVEAU : Obtenir une instruction courte pour l'affichage
  String getShortInstruction() {
    final direction = _getDirectionText();

    if (streetName != null && streetName!.isNotEmpty) {
      return '$direction sur $streetName';
    }

    return direction;
  }

  // Copier avec modifications
  NavigationStep copyWith({
    LatLng? startLocation,
    LatLng? endLocation,
    String? instruction,
    String? distance,
    int? distanceValue,
    String? duration,
    int? durationValue,
    String? maneuver,
    String? streetName, // ✅ NOUVEAU
  }) {
    return NavigationStep(
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      instruction: instruction ?? this.instruction,
      distance: distance ?? this.distance,
      distanceValue: distanceValue ?? this.distanceValue,
      duration: duration ?? this.duration,
      durationValue: durationValue ?? this.durationValue,
      maneuver: maneuver ?? this.maneuver,
      streetName: streetName ?? this.streetName, // ✅ NOUVEAU
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_location': {
        'lat': startLocation.latitude,
        'lng': startLocation.longitude,
      },
      'end_location': {
        'lat': endLocation.latitude,
        'lng': endLocation.longitude,
      },
      'html_instructions': instruction,
      'distance': {
        'text': distance,
        'value': distanceValue,
      },
      'duration': {
        'text': duration,
        'value': durationValue,
      },
      'maneuver': maneuver,
      'street_name': streetName, // ✅ NOUVEAU
    };
  }

  @override
  String toString() =>
      'NavigationStep(instruction: $instruction, distance: $distance, maneuver: $maneuver, street: $streetName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationStep &&
        other.startLocation == startLocation &&
        other.endLocation == endLocation &&
        other.instruction == instruction;
  }

  @override
  int get hashCode =>
      startLocation.hashCode ^ endLocation.hashCode ^ instruction.hashCode;
}