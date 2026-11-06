import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/models/robot_state.dart';
import 'package:robot_mesero/services/simulated_robot_service.dart';

void main() {
  group('Protocolo JSON', () {
    test('serializa comandos', () {
      expect(RobotCommand.go(3).encode(), '{"cmd":"go","table":3}');
      expect(RobotCommand.confirm.encode(), '{"cmd":"confirm"}');
      expect(RobotCommand.stop.encode(), '{"cmd":"stop"}');
    });

    test('parsea estado', () {
      final m = RobotMessage.tryParse(
          '{"state":"EN_RUTA","table":3,"battery":78,"obstacle":false}');
      expect(m!.status!.state, RobotState.enRuta);
      expect(m.status!.table, 3);
      expect(m.status!.battery, 78);
    });

    test('parsea evento de error', () {
      final m = RobotMessage.tryParse('{"event":"error","code":"LINE_LOST"}');
      expect(m!.event!.code, RobotEvent.lineLost);
    });

    test('ignora basura', () {
      expect(RobotMessage.tryParse('no es json'), isNull);
      expect(RobotMessage.tryParse('[1,2]'), isNull);
      expect(RobotMessage.tryParse('{"x":1}'), isNull);
    });
  });

  group('Robot simulado (§4.2)', () {
    SimulatedRobotService make() => SimulatedRobotService(
          travelTime: const Duration(seconds: 2),
          waitTimeout: const Duration(seconds: 5),
          obstacleTimeout: const Duration(seconds: 3),
        );

    test('ciclo completo: ruta, espera, confirmación, regreso, reposo', () {
      fakeAsync((async) {
        final r = make();
        r.connect();
        r.send(RobotCommand.go(3));
        expect(r.current.state, RobotState.enRuta);
        expect(r.current.table, 3);
        async.elapse(const Duration(seconds: 2));
        expect(r.current.state, RobotState.esperando);
        r.send(RobotCommand.confirm);
        expect(r.current.state, RobotState.regresando);
        async.elapse(const Duration(seconds: 2));
        expect(r.current.state, RobotState.reposo);
        expect(r.current.table, isNull);
        r.dispose();
      });
    });

    test('timeout de espera regresa a la base (RF-06)', () {
      fakeAsync((async) {
        final r = make();
        r.connect();
        r.send(RobotCommand.go(1));
        async.elapse(const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 5));
        expect(r.current.state, RobotState.regresando);
        r.dispose();
      });
    });

    test('obstáculo detiene y reanuda en el estado previo (RF-02/03)', () {
      fakeAsync((async) {
        final r = make();
        r.connect();
        r.send(RobotCommand.go(2));
        r.placeObstacle();
        expect(r.current.state, RobotState.obstaculo);
        r.clearObstacle();
        expect(r.current.state, RobotState.enRuta);
        expect(r.current.table, 2);
        r.dispose();
      });
    });

    test('obstáculo prolongado genera error y alerta', () {
      fakeAsync((async) {
        final r = make();
        final events = <RobotEvent>[];
        r.eventStream.listen(events.add);
        r.connect();
        r.send(RobotCommand.go(2));
        r.placeObstacle();
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();
        expect(r.current.state, RobotState.error);
        expect(events.single.code, RobotEvent.obstacleTimeout);
        r.dispose();
      });
    });

    test('paro de emergencia y reinicio manual (RF-08)', () {
      fakeAsync((async) {
        final r = make();
        r.connect();
        r.send(RobotCommand.go(2));
        r.send(RobotCommand.stop);
        expect(r.current.state, RobotState.paro);
        async.elapse(const Duration(seconds: 10));
        expect(r.current.state, RobotState.paro);
        r.send(RobotCommand.reset);
        expect(r.current.state, RobotState.reposo);
        r.dispose();
      });
    });

    test('ignora "go" si no está en reposo', () {
      fakeAsync((async) {
        final r = make();
        r.connect();
        r.send(RobotCommand.go(1));
        r.send(RobotCommand.go(4));
        expect(r.current.table, 1);
        r.dispose();
      });
    });
  });
}
