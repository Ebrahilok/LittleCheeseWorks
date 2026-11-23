import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

/// Punto proyectado a pantalla con su profundidad (distancia a lo largo de la vista).
class Projected {
  const Projected(this.offset, this.depth);
  final Offset offset;
  final double depth;
}

/// Cámara orbital alrededor de [target]. Convención de mundo: x → derecha,
/// y → arriba, z → hacia el espectador (el "y" del mapa 2D es el z del mundo).
class OrbitCamera {
  OrbitCamera({
    Vector3? target,
    this.yaw = 0.0,
    this.pitch = 0.75,
    this.distance = 8,
    this.fovY = 50 * pi / 180,
  }) : target = target ?? Vector3.zero();

  Vector3 target;
  double yaw;
  double pitch;
  double distance;
  final double fovY;

  static const minPitch = 0.1;
  static const maxPitch = 1.52;
  static const minDistance = 2.0;
  static const maxDistance = 20.0;

  Vector3 get position =>
      target +
      Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * distance;

  void orbit(double dYaw, double dPitch) {
    yaw += dYaw;
    pitch = (pitch + dPitch).clamp(minPitch, maxPitch);
  }

  void zoom(double factor) {
    distance = (distance * factor).clamp(minDistance, maxDistance);
  }

  CameraProjector projector(Size size) => CameraProjector(this, size);
}

class CameraProjector {
  CameraProjector(OrbitCamera cam, this.size) {
    _view = Matrix4.identity();
    setViewMatrix(_view, cam.position, cam.target, Vector3(0, 1, 0));
    _proj = makePerspectiveMatrix(
        cam.fovY, size.height == 0 ? 1 : size.width / size.height, 0.05, 100);
  }

  final Size size;
  late final Matrix4 _view;
  late final Matrix4 _proj;

  /// Devuelve null si el punto está detrás de la cámara.
  Projected? project(Vector3 p) {
    final v = Vector4(p.x, p.y, p.z, 1);
    _view.transform(v);
    final depth = -v.z;
    if (depth <= 0.05) return null;
    _proj.transform(v);
    final nx = v.x / v.w;
    final ny = v.y / v.w;
    return Projected(
      Offset((nx + 1) / 2 * size.width, (1 - ny) / 2 * size.height),
      depth,
    );
  }
}
