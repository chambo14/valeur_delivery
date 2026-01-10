import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationStep {
  final LatLng startLocation;
  final LatLng endLocation;
  final String instruction;
  final String distance;
  final int distanceValue; // en mètres
  final String duration;
  final int durationValue; // en secondes
  final String maneuver; // turn-left, turn-right, etc.

  NavigationStep({
    required this.startLocation,
    required this.endLocation,
    required this.instruction,
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    this.maneuver = '',
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      instruction: _cleanHtml(json['html_instructions']),
      distance: json['distance']['text'],
      distanceValue: json['distance']['value'],
      duration: json['duration']['text'],
      durationValue: json['duration']['value'],
      maneuver: json['maneuver'] ?? '',
    );
  }

  // Nettoyer le HTML des instructions
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');
  }

  // Obtenir l'icône selon la manœuvre
  String get maneuverIcon {
    switch (maneuver) {
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
      default:
        return '↑';
    }
  }

  @override
  String toString() => 'NavigationStep(instruction: $instruction, distance: $distance)';
}