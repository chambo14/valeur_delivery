// data/services/vehicle_icon_service.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum VehicleType {
  moto,
  car,
}

class VehicleIconService {
  static BitmapDescriptor? _motoIcon;
  static BitmapDescriptor? _carIcon;

  // Initialiser les icônes au démarrage de l'app
  static Future<void> initialize() async {
    _motoIcon = await _createVehicleIcon('assets/images/moto_marker.png');
    _carIcon = await _createVehicleIcon('assets/images/car_marker.png');
  }

  static Future<BitmapDescriptor> _createVehicleIcon(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 120, // Taille de l'icône
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      // Fallback si l'image n'existe pas
      return BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
    }
  }

  // Obtenir l'icône selon le type de véhicule
  static BitmapDescriptor getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.moto:
        return _motoIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );
      case VehicleType.car:
        return _carIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            );
    }
  }

  // Créer une icône avec rotation pour la direction
  static Future<BitmapDescriptor> createRotatedIcon(
      VehicleType type,
      double bearing,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 120.0;

    // Appliquer la rotation
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.rotate(bearing * 3.14159 / 180);
    canvas.translate(-size / 2, -size / 2);

    // Dessiner l'icône de base
    final paint = Paint()
      ..color = type == VehicleType.moto ? Colors.red : Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      paint,
    );

    // Dessiner une flèche pour indiquer la direction
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size / 2, size / 4);
    path.lineTo(size / 2 - 15, size / 2);
    path.lineTo(size / 2 + 15, size / 2);
    path.close();

    canvas.drawPath(path, arrowPaint..style = PaintingStyle.fill);

    // Ajouter un point blanc au centre
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      8,
      Paint()..color = Colors.white,
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Créer une icône personnalisée avec texte
  static Future<BitmapDescriptor> createVehicleMarkerWithLabel(
      VehicleType type,
      String label,
      double bearing,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(150, 150);

    // Fond circulaire
    final bgPaint = Paint()
      ..color = type == VehicleType.moto
          ? Colors.red.withOpacity(0.9)
          : Colors.blue.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      40,
      bgPaint,
    );

    // Bordure blanche
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      40,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Icône de véhicule (emoji ou texte)
    final textPainter = TextPainter(
      text: TextSpan(
        text: type == VehicleType.moto ? '🏍️' : '🚗',
        style: const TextStyle(fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );

    // Flèche directionnelle
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate((bearing - 90) * 3.14159 / 180);

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(0, -50);
    arrowPath.lineTo(-8, -35);
    arrowPath.lineTo(8, -35);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}