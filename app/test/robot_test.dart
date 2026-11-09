import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/models/robot_state.dart';
import 'package:robot_mesero/services/simulated_robot_service.dart';

void main() {
  group('Protocolo JSON', () {
    test('serializa comandos', () {
      expect(RobotCommand.calibrate.encode(), '{"cmd":"calibrate"}');
      expect(RobotCommand.goTo(2.5, 1).encode(), '{"cmd":"goto","x":2.5,"y":1.0}');
      expect(RobotCommand.unload.encode(), '{"cmd":"unload"}');
      expect(RobotCommand.stop.encode(), '{"cmd":"stop"}');
    });

    test('parsea estado', () {
      final m = RobotMessage.tryParse('{"state":"EN_RUTA","x":1.5,"y":0.5,'
          '"heading":0.3,"load":true,"calibrated":true,'
          '"target":{"x":3,"y":2},"battery":78,"obstacle":false}');
      final s = m!.status!;
      expect(s.state, RobotState.enRuta);
      expect(s.x, 1.5);
      expect(s.hasLoad, isTrue);
      expect(s.target!.dx, 3);
      expect(s.battery, 78);
    });

    test('parsea objeto detectado y objeto desaparecido', () {
      final seen = RobotMessage.tryParse(
          '{"event":"object","id":3,"x":1.2,"y":0.8,"w":0.3,"h":0.4}');
      expect(seen!.object!.object!.id, 3);
      expect(seen.object!.object!.h, 0.4);
      final gone = RobotMessage.tryParse('{"event":"object_gone","id":3}');
      expect(gone!.object!.removed, isTrue);
      expect(gone.object!.objectId, 3);
    });

    test('parsea evento de error', () {
      final m = RobotMessage.tryParse('{"event":"error","code":"LOW_BATTERY"}');
      expect(m!.event!.code, RobotEvent.lowBattery);
    });

    test('ignora basura', () {
      expect(RobotMessage.tryParse('no es json'), isNull);
      expect(RobotMessage.tryParse('[1,2]'), isNull);
      expect(RobotMessage.tryParse('{"x":1}'), isNull);
      expect(RobotMessage.tryParse('{"event":"object","id":"a"}'), isNull);
    });
  });

  group('Robot simulado', () {
    SimulatedRobotService make() => SimulatedRobotService(
          speed: 1.0,
          turnRate: 10,
          unloadTimeout: const Duration(seconds: 5),
          obstacleTimeout: const Duration(seconds: 3),
        );

    void start(SimulatedRobotService r, double x, double y) {
      r.connect();
      r.send(RobotCommand.calibrate);
      r.send(RobotCommand.goTo(x, y));
    }

    test('arranca esperando carga y sin calibrar', () {
      fakeAsync((a) {
        final r = make()..connect();
        expect(r.current.state, RobotState.esperandoCarga);
        expect(r.current.calibrated, isFalse);
        r.send(RobotCommand.goTo(1, 1)); // ignorado sin calibrar
        expect(r.current.state, RobotState.esperandoCarga);
        r.dispose();
      });
    });

    test('calibrar fija el origen y toma la carga', () {
      fakeAsync((a) {
        final r = make()..connect();
        r.send(RobotCommand.calibrate);
        expect(r.current.state, RobotState.listo);
        expect(r.current.calibrated, isTrue);
        expect(r.current.hasLoad, isTrue);
        expect(r.current.position, Offset.zero);
        r.dispose();
      });
    });

    test('lleva la carga al punto, espera retiro y regresa a la base', () {
      fakeAsync((a) {
        final r = make();
        start(r, 2, 1);
        expect(r.current.state, RobotState.enRuta);
        a.elapse(const Duration(seconds: 4));
        expect(r.current.state, RobotState.entregando);
        expect((r.current.position - const Offset(2, 1)).distance, lessThan(0.1));
        r.send(RobotCommand.unload);
        expect(r.current.state, RobotState.regresando);
        expect(r.current.hasLoad, isFalse);
        a.elapse(const Duration(seconds: 4));
        expect(r.current.state, RobotState.esperandoCarga);
        expect(r.current.position, Offset.zero);
        r.dispose();
      });
    });

    test('tras llegar se puede enviar a otro punto sin parar el robot', () {
      fakeAsync((a) {
        final r = make();
        start(r, 2, 0);
        a.elapse(const Duration(seconds: 3));
        expect(r.current.state, RobotState.entregando);
        r.send(RobotCommand.goTo(2, 2));
        expect(r.current.state, RobotState.enRuta);
        expect(r.current.hasLoad, isTrue);
        a.elapse(const Duration(seconds: 4));
        expect(r.current.state, RobotState.entregando);
        expect((r.current.position - const Offset(2, 2)).distance, lessThan(0.1));
        r.dispose();
      });
    });

    test('después de regresar a la base se puede enviar sin recalibrar', () {
      fakeAsync((a) {
        final r = make();
        start(r, 1, 0);
        a.elapse(const Duration(seconds: 2));
        r.send(RobotCommand.unload);
        a.elapse(const Duration(seconds: 3));
        expect(r.current.state, RobotState.esperandoCarga);
        r.send(RobotCommand.goTo(0, 2));
        expect(r.current.state, RobotState.enRuta);
        a.elapse(const Duration(seconds: 4));
        expect(r.current.state, RobotState.listo); // sin carga: no espera retiro
        expect((r.current.position - const Offset(0, 2)).distance, lessThan(0.1));
        r.dispose();
      });
    });

    test('también se puede redirigir mientras regresa', () {
      fakeAsync((a) {
        final r = make();
        start(r, 2, 0);
        a.elapse(const Duration(seconds: 3));
        r.send(RobotCommand.unload);
        a.elapse(const Duration(seconds: 1));
        expect(r.current.state, RobotState.regresando);
        r.send(RobotCommand.goTo(2, 2));
        expect(r.current.state, RobotState.enRuta);
        r.dispose();
      });
    });

    test('se puede cambiar el destino en pleno recorrido', () {
      fakeAsync((a) {
        final r = make();
        start(r, 4, 0);
        a.elapse(const Duration(seconds: 1));
        r.send(RobotCommand.goTo(1, 3));
        expect(r.current.target, const Offset(1, 3));
        a.elapse(const Duration(seconds: 6));
        expect(r.current.state, RobotState.entregando);
        r.dispose();
      });
    });

    test('sin retiro de carga regresa tras el timeout', () {
      fakeAsync((a) {
        final r = make();
        start(r, 1, 0);
        a.elapse(const Duration(seconds: 2));
        expect(r.current.state, RobotState.entregando);
        a.elapse(const Duration(seconds: 5));
        expect(r.current.state, RobotState.regresando);
        r.dispose();
      });
    });

    test('un objeto en la trayectoria detiene el robot y al quitarlo reanuda', () {
      fakeAsync((a) {
        final r = make();
        final id = r.placeObject(1.5, 0);
        start(r, 4, 0);
        a.elapse(const Duration(seconds: 3));
        expect(r.current.state, RobotState.obstaculo);
        expect(r.current.obstacle, isTrue);
        expect(r.current.x, lessThan(1.5)); // no lo atraviesa
        r.removeObject(id);
        a.elapse(const Duration(seconds: 1));
        expect(r.current.state, RobotState.enRuta);
        a.elapse(const Duration(seconds: 5));
        expect(r.current.state, RobotState.entregando);
        r.dispose();
      });
    });

    test('un objeto fuera de la trayectoria no bloquea', () {
      fakeAsync((a) {
        final r = make();
        r.placeObject(2, 1.5);
        start(r, 4, 0);
        a.elapse(const Duration(seconds: 6));
        expect(r.current.state, RobotState.entregando);
        r.dispose();
      });
    });

    test('obstáculo prolongado genera error y alerta', () {
      fakeAsync((a) {
        final r = make();
        final events = <RobotEvent>[];
        r.eventStream.listen(events.add);
        r.placeObject(1.5, 0);
        start(r, 4, 0);
        a.elapse(const Duration(seconds: 7));
        expect(r.current.state, RobotState.error);
        expect(events.map((e) => e.code), contains(RobotEvent.obstacleTimeout));
        r.dispose();
      });
    });

    test('detecta objetos dentro del rango del sensor y su desaparición', () {
      fakeAsync((a) {
        final r = make();
        final seen = <ObjectEvent>[];
        r.objectStream.listen(seen.add);
        r.connect();
        final near = r.placeObject(0.6, 0.6);
        r.placeObject(5, 3); // lejos: no se detecta
        a.elapse(const Duration(seconds: 1));
        expect(seen.length, 1);
        expect(seen.single.object!.x, 0.6);
        r.removeObject(near);
        a.elapse(const Duration(seconds: 1));
        expect(seen.last.removed, isTrue);
        expect(seen.last.objectId, near);
        r.dispose();
      });
    });

    test('paro de emergencia y reinicio', () {
      fakeAsync((a) {
        final r = make();
        start(r, 3, 0);
        a.elapse(const Duration(seconds: 1));
        r.send(RobotCommand.stop);
        final x = r.current.x;
        a.elapse(const Duration(seconds: 5));
        expect(r.current.state, RobotState.paro);
        expect(r.current.x, x);
        r.send(RobotCommand.reset);
        expect(r.current.state, RobotState.listo);
        r.dispose();
      });
    });

    test('el destino se limita al cuarto', () {
      fakeAsync((a) {
        final r = make();
        start(r, 100, 100);
        expect(r.current.target, const Offset(5.5, 3.5));
        r.dispose();
      });
    });
  });
}
