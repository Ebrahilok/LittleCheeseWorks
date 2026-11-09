import 'dart:ui';

/// Cuarto en coordenadas del mapa (metros). El origen (0,0) es la base,
/// fijada por el robot al calibrar. +x hacia la derecha, +y hacia abajo (vista superior).
class Room {
  const Room({this.minX = -0.5, this.minY = -0.5, this.maxX = 5.5, this.maxY = 3.5});

  final double minX, minY, maxX, maxY;

  double get width => maxX - minX;
  double get height => maxY - minY;
  Offset get center => Offset((minX + maxX) / 2, (minY + maxY) / 2);

  bool contains(Offset p) =>
      p.dx >= minX && p.dx <= maxX && p.dy >= minY && p.dy <= maxY;

  Offset clamp(Offset p) => Offset(p.dx.clamp(minX, maxX), p.dy.clamp(minY, maxY));

  static const standard = Room();
}

/// Objeto detectado por el robot (o colocado en la simulación).
class DetectedObject {
  const DetectedObject({
    required this.id,
    required this.x,
    required this.y,
    this.w = 0.3,
    this.h = 0.3,
    this.label = 'Objeto',
  });

  final int id;
  final double x, y, w, h;
  final String label;

  Offset get position => Offset(x, y);

  /// Radio aproximado para pruebas de colisión.
  double get radius => (w > h ? w : h) / 2;

  factory DetectedObject.fromJson(Map<String, dynamic> json) => DetectedObject(
        id: (json['id'] as num).toInt(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num?)?.toDouble() ?? 0.3,
        h: (json['h'] as num?)?.toDouble() ?? 0.3,
        label: json['label'] as String? ?? 'Objeto',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'x': x, 'y': y, 'w': w, 'h': h, 'label': label};
}

/// Punto con nombre guardado por el usuario.
class SavedPoint {
  const SavedPoint(this.name, this.x, this.y);
  final String name;
  final double x, y;
  Offset get position => Offset(x, y);
}
