import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/widgets/scene3d_math.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const size = Size(800, 600);

  test('el objetivo de la cámara se proyecta al centro de la pantalla', () {
    final cam = OrbitCamera(target: Vector3(2, 0, 1.5), yaw: 0.7, pitch: 0.6);
    final p = cam.projector(size).project(cam.target)!;
    expect(p.offset.dx, closeTo(400, 0.01));
    expect(p.offset.dy, closeTo(300, 0.01));
    expect(p.depth, closeTo(cam.distance, 0.01));
  });

  test('+x del mundo queda a la derecha y +z más abajo con yaw 0', () {
    final cam = OrbitCamera();
    final pr = cam.projector(size);
    expect(pr.project(Vector3(1, 0, 0))!.offset.dx, greaterThan(400));
    expect(pr.project(Vector3(0, 0, 1))!.offset.dy, greaterThan(300));
  });

  test('lo cercano tiene menor profundidad y lo de atrás de la cámara es null', () {
    final cam = OrbitCamera(pitch: 0.5);
    final pr = cam.projector(size);
    final near = pr.project(Vector3(0, 0, 2))!;
    final far = pr.project(Vector3(0, 0, -2))!;
    expect(near.depth, lessThan(far.depth));
    expect(pr.project(cam.position + (cam.position - cam.target)), isNull);
  });

  test('orbit limita el pitch y zoom limita la distancia', () {
    final cam = OrbitCamera();
    cam.orbit(0, 10);
    expect(cam.pitch, OrbitCamera.maxPitch);
    cam.orbit(0, -10);
    expect(cam.pitch, OrbitCamera.minPitch);
    cam.zoom(100);
    expect(cam.distance, OrbitCamera.maxDistance);
    cam.zoom(0.0001);
    expect(cam.distance, OrbitCamera.minDistance);
  });
}
