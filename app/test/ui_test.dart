import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/app.dart';
import 'package:robot_mesero/models/robot_state.dart';
import 'package:robot_mesero/models/world.dart';
import 'package:robot_mesero/widgets/scene3d.dart';

void main() {
  testWidgets('Scene3D dibuja robot, carga y objetos sin errores', (t) async {
    await t.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: Scene3D(
          status: const RobotStatus(
            state: RobotState.enRuta,
            x: 1,
            y: 1,
            heading: 0.5,
            hasLoad: true,
            calibrated: true,
            target: Offset(3, 2),
          ),
          objects: const [DetectedObject(id: 1, x: 2, y: 1)],
          room: Room.standard,
          follow: true,
        ),
      ),
    ));
    await t.drag(find.byType(Scene3D), const Offset(60, 20));
    await t.pump();
    expect(tester(t), isNull);
  });

  testWidgets('App: simulación, calibrar y ver mapa/3D/estado', (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const ProviderScope(child: RobotCargaApp()));
    await t.tap(find.text('Modo simulación'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Ya coloqué el objeto: Calibrar'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Calibrado'), findsOneWidget);

    await t.tap(find.text('Mapa'));
    await t.pump();
    await t.tapAt(t.getCenter(find.byKey(const Key('mapCanvas'))));
    await t.pump();
    expect(find.textContaining('Destino:'), findsOneWidget);
    await t.tap(find.text('Llevar aquí'));
    await t.pump(const Duration(milliseconds: 500));

    await t.tap(find.text('3D'));
    await t.pump();
    expect(find.byType(Scene3D), findsOneWidget);

    await t.tap(find.text('Estado'));
    await t.pump();
    expect(find.byKey(const Key('stateLabel')), findsOneWidget);

    // Desmonta la app para cancelar los temporizadores del simulador.
    await t.pumpWidget(const SizedBox());
  });
}

Object? tester(WidgetTester t) => t.takeException();
