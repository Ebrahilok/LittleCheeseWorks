// Pruebas con un servidor WebSocket real en localhost que hace de ESP32.
// Este archivo no debe usar testWidgets: su binding bloquea las conexiones de red.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:robot_mesero/models/robot_state.dart';
import 'package:robot_mesero/services/websocket_robot_service.dart';

/// ESP32 de mentira: acepta clientes, guarda lo que recibe y puede "apagarse".
class FakeRobot {
  HttpServer? _server;
  final sockets = <WebSocket>[];
  final received = <String>[];
  int port = 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    port = _server!.port;
    _server!.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      sockets.add(ws);
      ws.listen((m) => received.add(m as String), onDone: () => sockets.remove(ws));
    });
  }

  void sendAll(String msg) {
    for (final s in sockets) {
      s.add(msg);
    }
  }

  Future<void> stop() async {
    for (final s in sockets.toList()) {
      await s.close();
    }
    sockets.clear();
    await _server?.close(force: true);
    _server = null;
  }
}

const _status = '{"state":"LISTO","x":0,"y":0,"heading":0,"load":true,'
    '"calibrated":true,"battery":90,"obstacle":false}';

Future<void> until(bool Function() cond, {String? what}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) fail('Tiempo agotado esperando: $what');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late FakeRobot robot;
  late WebSocketRobotService service;
  late List<bool> connected;
  late List<RobotEvent> events;
  late List<RobotStatus> statuses;

  setUp(() async {
    robot = FakeRobot();
    await robot.start();
    service = WebSocketRobotService(
      Uri.parse('ws://127.0.0.1:${robot.port}'),
      silenceTimeout: const Duration(milliseconds: 600),
      reconnectDelay: const Duration(milliseconds: 100),
      maxReconnectDelay: const Duration(milliseconds: 300),
    );
    connected = [];
    events = [];
    statuses = [];
    service.connectedStream.listen(connected.add);
    service.eventStream.listen(events.add);
    service.statusStream.listen(statuses.add);
  });

  tearDown(() async {
    await service.dispose();
    await robot.stop();
  });

  test('conecta, recibe estado y envía comandos', () async {
    await service.connect();
    await until(() => robot.sockets.isNotEmpty, what: 'cliente en el servidor');
    robot.sendAll(_status);
    await until(() => statuses.isNotEmpty, what: 'estado');
    expect(statuses.single.state, RobotState.listo);
    expect(connected, [true]);

    service.send(RobotCommand.goTo(1, 2));
    await until(() => robot.received.isNotEmpty, what: 'comando');
    expect(robot.received.single, '{"cmd":"goto","x":1.0,"y":2.0}');
  });

  test('el primer intento fallido lanza y no deja reintentos', () async {
    await robot.stop();
    await expectLater(service.connect(), throwsA(anything));
    expect(connected, isEmpty);
  });

  test('si el robot se apaga avisa una vez y se reconecta cuando vuelve', () async {
    await service.connect();
    await until(() => robot.sockets.isNotEmpty, what: 'cliente en el servidor');
    await robot.stop();
    await until(() => connected.contains(false), what: 'aviso de desconexión');
    // Varios reintentos fallidos no deben repetir la alerta.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(connected, [true, false]);
    expect(events.where((e) => e.code == RobotEvent.connectionLost).length, 1);

    // Sin conexión los comandos se descartan sin lanzar.
    service.send(RobotCommand.stop);

    await robot.start(); // mismo puerto
    await until(() => connected.length == 3, what: 'reconexión');
    expect(connected, [true, false, true]);
    await until(() => robot.sockets.isNotEmpty, what: 'cliente tras reconectar');
    robot.sendAll(_status);
    await until(() => statuses.isNotEmpty, what: 'estado tras reconectar');
    service.send(RobotCommand.reset);
    await until(() => robot.received.isNotEmpty, what: 'comando tras reconectar');
    expect(robot.received, ['{"cmd":"reset"}']);
  });

  test('el silencio prolongado cuenta como desconexión y luego se recupera', () async {
    await service.connect();
    await until(() => robot.sockets.isNotEmpty, what: 'cliente en el servidor');
    // El servidor sigue vivo pero no manda nada: 600 ms de silencio.
    await until(() => connected.contains(false), what: 'aviso por silencio');
    expect(events.single.code, RobotEvent.connectionLost);
    await until(() => connected.length == 3, what: 'reconexión');
    expect(connected.last, isTrue);
  });

  test('dispose detiene los reintentos', () async {
    await service.connect();
    await until(() => robot.sockets.isNotEmpty, what: 'cliente en el servidor');
    await robot.stop();
    await until(() => connected.contains(false), what: 'aviso de desconexión');
    await service.dispose();
    await robot.start();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(robot.sockets, isEmpty);
  });
}
