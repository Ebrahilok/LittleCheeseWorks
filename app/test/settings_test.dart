import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/models/robot_state.dart';
import 'package:robot_mesero/models/world.dart';
import 'package:robot_mesero/providers/robot_provider.dart';
import 'package:robot_mesero/services/settings_store.dart';

void main() {
  group('Cuarto', () {
    test('fromSize coloca la base a la distancia indicada de las paredes', () {
      const r = Room.fromSize(width: 4, height: 3, baseX: 1, baseY: 0.5);
      expect(r.minX, -1);
      expect(r.maxX, 3);
      expect(r.minY, -0.5);
      expect(r.maxY, 2.5);
      expect(r.width, 4);
      expect(r.height, 3);
      expect(r.isValid, isTrue);
    });

    test('el cuarto estándar equivale a 6 × 4 m con la base a 0.5 m', () {
      expect(const Room.fromSize(width: 6, height: 4), Room.standard);
    });

    test('rechaza cuartos demasiado chicos, enormes o con la base fuera', () {
      expect(const Room.fromSize(width: 0.5, height: 3).isValid, isFalse);
      expect(const Room.fromSize(width: 30, height: 3).isValid, isFalse);
      expect(const Room.fromSize(width: 4, height: 3, baseX: 5).isValid, isFalse);
      expect(const Room.fromSize(width: 4, height: 3, baseY: -1).isValid, isFalse);
    });
  });

  group('Ajustes guardados', () {
    test('se codifican y decodifican sin perder datos', () {
      const s = AppSettings(
        host: '192.168.1.50',
        room: Room.fromSize(width: 4, height: 3, baseX: 1, baseY: 1),
        points: [SavedPoint('Mesa', 2.5, 1.25)],
      );
      final back = AppSettings.decode(s.encode());
      expect(back.host, '192.168.1.50');
      expect(back.room, s.room);
      expect(back.points.single.name, 'Mesa');
      expect(back.points.single.position, const Offset(2.5, 1.25));
    });

    test('datos dañados o ausentes dan los valores por defecto', () {
      for (final raw in [null, 'no es json', '[1]', '{"room":5}', '{"host":"x"}']) {
        final s = AppSettings.decode(raw);
        expect(s.host, AppSettings.defaultHost, reason: '$raw');
        expect(s.room, Room.standard, reason: '$raw');
        expect(s.points, isEmpty, reason: '$raw');
      }
    });

    test('un cuarto inválido guardado se sustituye por el estándar', () {
      final s = AppSettings.decode(
          '{"host":"h","room":{"minX":1,"minY":1,"maxX":2,"maxY":2},"points":[]}');
      expect(s.room, Room.standard);
      expect(s.host, 'h');
    });
  });

  group('Controlador', () {
    (ProviderContainer, MemorySettingsStore) make([AppSettings? initial]) {
      final store = MemorySettingsStore(initial ?? const AppSettings());
      final c = ProviderContainer(
          overrides: [settingsStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      return (c, store);
    }

    test('arranca con los ajustes guardados', () {
      final (c, _) = make(const AppSettings(
        host: '10.0.0.7',
        room: Room.fromSize(width: 3, height: 3),
        points: [SavedPoint('A', 1, 1)],
      ));
      final s = c.read(robotProvider);
      expect(s.host, '10.0.0.7');
      expect(s.room.width, 3);
      expect(s.savedPoints.single.name, 'A');
    });

    test('guardar y borrar puntos se persiste', () {
      final (c, store) = make();
      final ctrl = c.read(robotProvider.notifier);
      ctrl.savePoint('Mesa', const Offset(2, 1));
      expect(store.load().points.single.name, 'Mesa');
      ctrl.deletePoint(c.read(robotProvider).savedPoints.single);
      expect(store.load().points, isEmpty);
    });

    test('setRoom guarda los cuartos válidos y rechaza los inválidos', () {
      final (c, store) = make();
      final ctrl = c.read(robotProvider.notifier);
      const ok = Room.fromSize(width: 8, height: 5, baseX: 1, baseY: 1);
      expect(ctrl.setRoom(ok), isTrue);
      expect(c.read(robotProvider).room, ok);
      expect(store.load().room, ok);
      expect(ctrl.setRoom(const Room.fromSize(width: 0.2, height: 5)), isFalse);
      expect(c.read(robotProvider).room, ok);
    });

    test('el simulador usa el cuarto configurado y sus cambios', () {
      fakeAsync((a) {
        final (c, _) = make();
        final ctrl = c.read(robotProvider.notifier);
        ctrl.setRoom(const Room.fromSize(width: 3, height: 2));
        ctrl.connectSimulated();
        a.flushMicrotasks();
        ctrl.calibrate();
        ctrl.goTo(const Offset(50, 50));
        a.flushMicrotasks();
        expect(c.read(robotProvider).status.target, const Offset(2.5, 1.5));

        ctrl.setRoom(const Room.fromSize(width: 10, height: 10));
        ctrl.goTo(const Offset(50, 50));
        a.flushMicrotasks();
        expect(c.read(robotProvider).status.target, const Offset(9.5, 9.5));
        ctrl.disconnect();
        a.flushMicrotasks();
      });
    });

    test('registra el recorrido y lo reinicia al volver a la base', () {
      fakeAsync((a) {
        final (c, _) = make();
        final ctrl = c.read(robotProvider.notifier);
        ctrl.connectSimulated();
        a.flushMicrotasks();
        ctrl.calibrate();
        ctrl.goTo(const Offset(1, 0));
        a.elapse(const Duration(seconds: 4));
        var s = c.read(robotProvider);
        expect(s.status.state, RobotState.entregando);
        expect(s.trail.length, greaterThan(10));
        expect(s.trail.first.distance, lessThan(0.1));
        expect((s.trail.last - const Offset(1, 0)).distance, lessThan(0.1));
        expect(s.distanceToTarget, lessThan(0.1));

        ctrl.unload();
        a.elapse(const Duration(seconds: 6));
        s = c.read(robotProvider);
        expect(s.status.state, RobotState.esperandoCarga);
        expect(s.trail, isEmpty);
        expect(s.distanceToTarget, isNull);
        ctrl.disconnect();
        a.flushMicrotasks();
      });
    });

    test('borrar el historial de alertas', () {
      fakeAsync((a) {
        final (c, _) = make();
        final ctrl = c.read(robotProvider.notifier);
        ctrl.connectSimulated();
        a.flushMicrotasks();
        ctrl.simulator!.placeObject(0.5, 0.5);
        a.elapse(const Duration(seconds: 1));
        expect(c.read(robotProvider).alerts, isNotEmpty);
        expect(c.read(robotProvider).unreadAlerts, greaterThan(0));
        ctrl.clearAlerts();
        expect(c.read(robotProvider).alerts, isEmpty);
        expect(c.read(robotProvider).unreadAlerts, 0);
        ctrl.disconnect();
        a.flushMicrotasks();
      });
    });
  });
}
