import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../models/robot_state.dart';
import '../models/world.dart';
import 'scene3d_math.dart';

/// Visor 3D del cuarto, el robot y los objetos. Arrastrar = girar,
/// rueda / pellizco = zoom.
class Scene3D extends StatefulWidget {
  const Scene3D({
    super.key,
    required this.status,
    required this.objects,
    required this.room,
    this.follow = false,
    this.resetSignal = 0,
  });

  final RobotStatus status;
  final List<DetectedObject> objects;
  final Room room;
  final bool follow;

  /// Cambiar este valor recentra la cámara.
  final int resetSignal;

  @override
  State<Scene3D> createState() => _Scene3DState();
}

class _Scene3DState extends State<Scene3D> {
  final _camera = OrbitCamera();
  double _zoomStart = 8;

  @override
  void didUpdateWidget(Scene3D old) {
    super.didUpdateWidget(old);
    if (old.resetSignal != widget.resetSignal) {
      _camera
        ..yaw = 0
        ..pitch = 0.75
        ..distance = 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.room.center;
    final focus = widget.follow ? widget.status.position : c;
    _camera.target = Vector3(focus.dx, 0, focus.dy);
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          setState(() => _camera.zoom(1 + e.scrollDelta.dy * 0.001));
        }
      },
      child: GestureDetector(
        onScaleStart: (_) => _zoomStart = _camera.distance,
        onScaleUpdate: (d) => setState(() {
          _camera.orbit(-d.focalPointDelta.dx * 0.01, d.focalPointDelta.dy * 0.01);
          if (d.pointerCount > 1) {
            _camera.distance = (_zoomStart / d.scale)
                .clamp(OrbitCamera.minDistance, OrbitCamera.maxDistance);
          }
        }),
        child: ClipRect(
          child: CustomPaint(
            painter: _ScenePainter(
              camera: _camera,
              status: widget.status,
              objects: widget.objects,
              room: widget.room,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Face {
  _Face(this.pts, this.color);
  final List<Vector3> pts;
  final Color color;
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.camera,
    required this.status,
    required this.objects,
    required this.room,
  });

  final OrbitCamera camera;
  final RobotStatus status;
  final List<DetectedObject> objects;
  final Room room;

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;

  // Mapa (x, y) → mundo (x, altura, z).
  static Vector3 _w(double x, double h, double y) => Vector3(x, h, y);

  @override
  void paint(Canvas canvas, Size size) {
    final proj = camera.projector(size);
    final bg = Paint()..color = const Color(0xFFE8EEF4);
    canvas.drawRect(Offset.zero & size, bg);

    void polygon(List<Vector3> pts, Color fill, {Color? stroke}) {
      final ps = <Offset>[];
      for (final p in pts) {
        final q = proj.project(p);
        if (q == null) return;
        ps.add(q.offset);
      }
      final path = Path()..addPolygon(ps, true);
      canvas.drawPath(path, Paint()..color = fill);
      if (stroke != null) {
        canvas.drawPath(
            path,
            Paint()
              ..color = stroke
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }

    void line(Vector3 a, Vector3 b, Paint p) {
      final qa = proj.project(a), qb = proj.project(b);
      if (qa != null && qb != null) canvas.drawLine(qa.offset, qb.offset, p);
    }

    // Piso.
    polygon([
      _w(room.minX, 0, room.minY),
      _w(room.maxX, 0, room.minY),
      _w(room.maxX, 0, room.maxY),
      _w(room.minX, 0, room.maxY),
    ], const Color(0xFFF7F4EC), stroke: const Color(0xFF8A8F98));

    // Cuadrícula cada 0.5 m.
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = (room.minX * 2).ceil() / 2; x <= room.maxX; x += 0.5) {
      line(_w(x, 0, room.minY), _w(x, 0, room.maxY), grid);
    }
    for (var y = (room.minY * 2).ceil() / 2; y <= room.maxY; y += 0.5) {
      line(_w(room.minX, 0, y), _w(room.maxX, 0, y), grid);
    }

    // Base (origen).
    polygon([
      _w(-0.25, 0.003, -0.25),
      _w(0.25, 0.003, -0.25),
      _w(0.25, 0.003, 0.25),
      _w(-0.25, 0.003, 0.25),
    ], const Color(0x6643A047), stroke: const Color(0xFF2E7D32));

    // Destino y trayectoria.
    final t = status.target;
    if (t != null) {
      line(
          _w(status.x, 0.01, status.y),
          _w(t.dx, 0.01, t.dy),
          Paint()
            ..color = const Color(0xFF1E88E5)
            ..strokeWidth = 2);
      const r = 0.18;
      polygon([
        _w(t.dx, 0.004, t.dy - r),
        _w(t.dx + r, 0.004, t.dy),
        _w(t.dx, 0.004, t.dy + r),
        _w(t.dx - r, 0.004, t.dy),
      ], const Color(0x88E53935), stroke: const Color(0xFFC62828));
    }

    // Paredes bajas translúcidas.
    const wallH = 0.5;
    final faces = <_Face>[];
    const wallColor = Color(0x33607D8B);
    void wall(double x1, double y1, double x2, double y2) => faces.add(_Face([
          _w(x1, 0, y1),
          _w(x2, 0, y2),
          _w(x2, wallH, y2),
          _w(x1, wallH, y1),
        ], wallColor));
    wall(room.minX, room.minY, room.maxX, room.minY);
    wall(room.maxX, room.minY, room.maxX, room.maxY);
    wall(room.maxX, room.maxY, room.minX, room.maxY);
    wall(room.minX, room.maxY, room.minX, room.minY);

    // Objetos detectados.
    for (final o in objects) {
      faces.addAll(_box(o.x, o.y, o.w, o.h, 0, 0.3, 0, const Color(0xFFD84315)));
    }

    // Robot.
    final h = status.heading;
    final rx = status.x, ry = status.y;
    final body = status.state == RobotState.paro || status.state == RobotState.error
        ? const Color(0xFFC62828)
        : const Color(0xFF1565C0);
    faces.addAll(_box(rx, ry, 0.40, 0.30, 0.04, 0.12, h, body));
    // Ruedas.
    for (final side in [-1.0, 1.0]) {
      final ox = -sin(h) * side * 0.18, oy = cos(h) * side * 0.18;
      faces.addAll(_box(rx + ox, ry + oy, 0.12, 0.04, 0, 0.09, h, const Color(0xFF263238)));
    }
    // Indicador frontal.
    faces.addAll(_box(rx + cos(h) * 0.17, ry + sin(h) * 0.17, 0.06, 0.12, 0.16,
        0.19, h, const Color(0xFFFFEB3B)));
    // Carga sobre la bandeja.
    if (status.hasLoad) {
      faces.addAll(_box(rx, ry, 0.16, 0.16, 0.16, 0.30, h, const Color(0xFFFFA000)));
    }

    // Algoritmo del pintor: caras lejanas primero.
    final cam = camera.position;
    double dist(_Face f) {
      var c = Vector3.zero();
      for (final p in f.pts) {
        c += p;
      }
      c /= f.pts.length.toDouble();
      return (c - cam).length;
    }

    final sorted = faces.map((f) => (f, dist(f))).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    const light = [0.35, 0.85, 0.4];
    for (final (f, _) in sorted) {
      final n = (f.pts[1] - f.pts[0]).cross(f.pts[2] - f.pts[0])..normalize();
      final k = (0.55 + 0.45 * (n.x * light[0] + n.y * light[1] + n.z * light[2]).abs())
          .clamp(0.0, 1.0);
      final c = f.color;
      final shaded = Color.fromARGB(
        (c.a * 255).round(),
        (c.r * 255 * k).round().clamp(0, 255),
        (c.g * 255 * k).round().clamp(0, 255),
        (c.b * 255 * k).round().clamp(0, 255),
      );
      polygon(f.pts, shaded, stroke: const Color(0x55000000));
    }
  }

  /// Caja de tamaño [w]×[d] (largo × ancho local), desde [y0] hasta [y0]+[hgt],
  /// centrada en el punto del mapa ([cx],[cy]) y girada [rot] rad.
  List<_Face> _box(double cx, double cy, double w, double d, double y0,
      double hgt, double rot, Color color) {
    final top = y0 + hgt;
    final c = cos(rot), s = sin(rot);
    Vector3 p(double lx, double ly, double yy) =>
        Vector3(cx + lx * c - ly * s, yy, cy + lx * s + ly * c);
    final hw = w / 2, hd = d / 2;
    final b = [p(-hw, -hd, y0), p(hw, -hd, y0), p(hw, hd, y0), p(-hw, hd, y0)];
    final t = [p(-hw, -hd, top), p(hw, -hd, top), p(hw, hd, top), p(-hw, hd, top)];
    return [
      _Face([t[0], t[1], t[2], t[3]], color),
      for (var i = 0; i < 4; i++)
        _Face([b[i], b[(i + 1) % 4], t[(i + 1) % 4], t[i]], color),
    ];
  }
}
