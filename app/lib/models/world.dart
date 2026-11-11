import 'dart:ui';

/// Cuarto en coordenadas del mapa (metros). El origen (0,0) es la base,
/// fijada por el robot al calibrar. +x hacia la derecha, +y hacia abajo (vista superior).
class Room {
  const Room({this.minX = -0.5, this.minY = -0.5, this.maxX = 5.5, this.maxY = 3.5});

  /// Cuarto de [width] × [height] metros con la base a [baseX] m de la pared
  /// izquierda y [baseY] m de la pared superior (vista superior).
  const Room.fromSize({
    required double width,
    required double height,
    double baseX = 0.5,
    double baseY = 0.5,
  })  : minX = -baseX,
        minY = -baseY,
        maxX = width - baseX,
        maxY = height - baseY;

  final double minX, minY, maxX, maxY;

  double get width => maxX - minX;
  double get height => maxY - minY;

  /// Distancia de la base a la pared izquierda / superior.
  double get baseX => -minX;
  double get baseY => -minY;
  Offset get center => Offset((minX + maxX) / 2, (minY + maxY) / 2);

  /// Un cuarto es válido si mide entre 1 y 20 m por lado y contiene la base.
  bool get isValid =>
      width >= minSide &&
      height >= minSide &&
      width <= maxSide &&
      height <= maxSide &&
      contains(Offset.zero);

  static const minSide = 1.0;
  static const maxSide = 20.0;

  bool contains(Offset p) =>
      p.dx >= minX && p.dx <= maxX && p.dy >= minY && p.dy <= maxY;

  Offset clamp(Offset p) => Offset(p.dx.clamp(minX, maxX), p.dy.clamp(minY, maxY));

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        minX: (json['minX'] as num).toDouble(),
        minY: (json['minY'] as num).toDouble(),
        maxX: (json['maxX'] as num).toDouble(),
        maxY: (json['maxY'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() =>
      {'minX': minX, 'minY': minY, 'maxX': maxX, 'maxY': maxY};

  @override
  bool operator ==(Object other) =>
      other is Room &&
      other.minX == minX &&
      other.minY == minY &&
      other.maxX == maxX &&
      other.maxY == maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);

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

  factory SavedPoint.fromJson(Map<String, dynamic> json) => SavedPoint(
        json['name'] as String,
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'x': x, 'y': y};
}
