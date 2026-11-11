import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../models/world.dart';
import '../services/robot_service.dart';
import '../services/settings_store.dart';
import '../services/simulated_robot_service.dart';
import '../services/websocket_robot_service.dart';

class AlertEntry {
  AlertEntry(this.event) : at = event.at;
  final RobotEvent event;
  final DateTime at;
}

class RobotSession {
  const RobotSession({
    this.connected = false,
    this.reconnecting = false,
    this.simulated = false,
    this.status = const RobotStatus(),
    this.objects = const [],
    this.savedPoints = const [],
    this.alerts = const [],
    this.unreadAlerts = 0,
    this.room = Room.standard,
    this.host = AppSettings.defaultHost,
    this.trail = const [],
  });

  final bool connected;

  /// La conexión con el robot real se cayó y la app está reintentando.
  final bool reconnecting;
  final bool simulated;
  final RobotStatus status;
  final List<DetectedObject> objects;
  final List<SavedPoint> savedPoints;
  final List<AlertEntry> alerts;
  final int unreadAlerts;
  final Room room;

  /// Última IP usada para el robot real.
  final String host;

  /// Recorrido del robot desde que salió de la base (para dibujarlo en el mapa).
  final List<Offset> trail;

  /// Metros en línea recta hasta el destino activo, o null si no hay destino.
  double? get distanceToTarget =>
      status.target == null ? null : (status.target! - status.position).distance;

  RobotSession copyWith({
    bool? connected,
    bool? reconnecting,
    RobotStatus? status,
    List<DetectedObject>? objects,
    List<SavedPoint>? savedPoints,
    List<AlertEntry>? alerts,
    int? unreadAlerts,
    Room? room,
    String? host,
    List<Offset>? trail,
  }) =>
      RobotSession(
        connected: connected ?? this.connected,
        reconnecting: reconnecting ?? this.reconnecting,
        simulated: simulated,
        status: status ?? this.status,
        objects: objects ?? this.objects,
        savedPoints: savedPoints ?? this.savedPoints,
        alerts: alerts ?? this.alerts,
        unreadAlerts: unreadAlerts ?? this.unreadAlerts,
        room: room ?? this.room,
        host: host ?? this.host,
        trail: trail ?? this.trail,
      );
}

class RobotController extends Notifier<RobotSession> {
  RobotService? _service;
  final _subs = <StreamSubscription<dynamic>>[];

  /// Separación mínima entre puntos del recorrido y máximo de puntos guardados.
  static const _trailStep = 0.03;
  static const _trailMax = 600;

  @override
  RobotSession build() {
    ref.onDispose(_teardown);
    final saved = ref.read(settingsStoreProvider).load();
    return RobotSession(
        room: saved.room, savedPoints: saved.points, host: saved.host);
  }

  SimulatedRobotService? get simulator =>
      _service is SimulatedRobotService ? _service as SimulatedRobotService : null;

  Future<void> connectSimulated() =>
      _connect(SimulatedRobotService(room: state.room), true);

  Future<void> connectReal(String host, {int port = 81}) {
    state = state.copyWith(host: host);
    _persist();
    return _connect(WebSocketRobotService(Uri.parse('ws://$host:$port')), false);
  }

  /// Sesión limpia que conserva lo que el usuario configuró.
  RobotSession _fresh({bool simulated = false}) => RobotSession(
        simulated: simulated,
        savedPoints: state.savedPoints,
        room: state.room,
        host: state.host,
      );

  Future<void> _connect(RobotService service, bool simulated) async {
    await _teardown();
    _service = service;
    state = _fresh(simulated: simulated);
    _subs
      ..add(service.statusStream.listen(_onStatus))
      ..add(service.connectedStream.listen(_onConnected))
      ..add(service.eventStream.listen(_addAlert))
      ..add(service.objectStream.listen(_onObject));
    await service.connect();
  }

  void _onConnected(bool connected) => state = state.copyWith(
        connected: connected,
        // Solo el robot real se reconecta solo; el simulado nunca se cae.
        reconnecting: !connected && !state.simulated,
      );

  void _onStatus(RobotStatus s) {
    var trail = state.trail;
    if (!s.calibrated || s.state == RobotState.esperandoCarga) {
      // De vuelta en la base (o sin origen): empieza un recorrido nuevo.
      trail = const [];
    } else if (trail.isEmpty || (trail.last - s.position).distance >= _trailStep) {
      trail = [...trail, s.position];
      if (trail.length > _trailMax) {
        trail = trail.sublist(trail.length - _trailMax);
      }
    }
    state = state.copyWith(status: s, trail: trail);
  }

  void _addAlert(RobotEvent e) {
    state = state.copyWith(
      alerts: [AlertEntry(e), ...state.alerts],
      unreadAlerts: state.unreadAlerts + 1,
    );
  }

  void _onObject(ObjectEvent e) {
    final others = state.objects.where((o) => o.id != e.objectId).toList();
    if (e.removed) {
      state = state.copyWith(objects: others);
      return;
    }
    final o = e.object!;
    state = state.copyWith(objects: [...others, o]);
    _addAlert(RobotEvent(
      RobotEvent.objectDetected,
      detail: '(${o.x.toStringAsFixed(1)}, ${o.y.toStringAsFixed(1)}) m',
    ));
  }

  void markAlertsRead() => state = state.copyWith(unreadAlerts: 0);

  void clearAlerts() => state = state.copyWith(alerts: const [], unreadAlerts: 0);

  void calibrate() => _service?.send(RobotCommand.calibrate);
  void goTo(Offset p) => _service?.send(RobotCommand.goTo(p.dx, p.dy));
  void unload() => _service?.send(RobotCommand.unload);
  void emergencyStop() => _service?.send(RobotCommand.stop);
  void reset() => _service?.send(RobotCommand.reset);

  void savePoint(String name, Offset p) {
    state = state.copyWith(
        savedPoints: [...state.savedPoints, SavedPoint(name, p.dx, p.dy)]);
    _persist();
  }

  void deletePoint(SavedPoint p) {
    state = state.copyWith(
        savedPoints: state.savedPoints.where((s) => s != p).toList());
    _persist();
  }

  /// Cambia las medidas del cuarto. Devuelve false si no es un cuarto válido.
  bool setRoom(Room room) {
    if (!room.isValid) return false;
    state = state.copyWith(room: room);
    simulator?.room = room;
    _persist();
    return true;
  }

  void _persist() {
    final s = state;
    // Guardar es "mejor esfuerzo": si falla, la sesión actual sigue funcionando.
    unawaited(ref
        .read(settingsStoreProvider)
        .save(AppSettings(host: s.host, room: s.room, points: s.savedPoints))
        .catchError((Object _) {}));
  }

  Future<void> disconnect() async {
    await _teardown();
    state = _fresh();
  }

  Future<void> _teardown() async {
    // El servicio se detiene primero (de forma síncrona cancela sus temporizadores).
    final disposing = _service?.dispose();
    _service = null;
    // Se vacía la lista antes de esperar: dos cierres seguidos (desconectar y
    // cerrar la app) no deben pisarse.
    final subs = _subs.toList();
    _subs.clear();
    for (final s in subs) {
      await s.cancel();
    }
    await disposing;
  }
}

final robotProvider =
    NotifierProvider<RobotController, RobotSession>(RobotController.new);
