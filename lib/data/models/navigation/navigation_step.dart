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

  NavigationStep({
    required this.startLocation,
    required this.endLocation,
    required this.instruction,
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    this.maneuver,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    // Parsing sécurisé des coordonnées
    final startLoc = json['start_location'] as Map<String, dynamic>?;
    final endLoc = json['end_location'] as Map<String, dynamic>?;
    final distanceData = json['distance'] as Map<String, dynamic>?;
    final durationData = json['duration'] as Map<String, dynamic>?;

    return NavigationStep(
      startLocation: LatLng(
        _parseDouble(startLoc?['lat']) ?? 0.0,
        _parseDouble(startLoc?['lng']) ?? 0.0,
      ),
      endLocation: LatLng(
        _parseDouble(endLoc?['lat']) ?? 0.0,
        _parseDouble(endLoc?['lng']) ?? 0.0,
      ),
      instruction: _cleanHtml(json['html_instructions'] as String? ?? ''),
      distance: distanceData?['text'] as String? ?? '',
      distanceValue: _parseInt(distanceData?['value']) ?? 0,
      duration: durationData?['text'] as String? ?? '',
      durationValue: _parseInt(durationData?['value']) ?? 0,
      maneuver: json['maneuver'] as String?,
    );
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
    };
  }

  @override
  String toString() =>
      'NavigationStep(instruction: $instruction, distance: $distance, maneuver: $maneuver)';

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