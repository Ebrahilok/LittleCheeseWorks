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

  testWidgets('App: editar las medidas del cuarto', (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const ProviderScope(child: RobotCargaApp()));
    expect(find.text('Cuarto: 6 × 4 m'), findsOneWidget);

    await t.tap(find.text('Cuarto: 6 × 4 m'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('roomWidth')), '0.3');
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();
    expect(find.textContaining('Cada lado debe medir'), findsOneWidget);

    await t.enterText(find.byKey(const Key('roomWidth')), '8');
    await t.enterText(find.byKey(const Key('roomHeight')), '5,5'); // coma decimal
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();
    expect(find.text('Cuarto: 8 × 5.50 m'), findsOneWidget);
  });

  testWidgets('App: preajuste de cuarto de clase 2 × 2 m', (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const ProviderScope(child: RobotCargaApp()));
    await t.tap(find.text('Cuarto: 6 × 4 m'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('presetClase')));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar'));
    await t.pumpAndSettle();
    expect(find.text('Cuarto: 2 × 2 m'), findsOneWidget);
    expect(find.textContaining('Base a 0.25 m'), findsOneWidget);
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
