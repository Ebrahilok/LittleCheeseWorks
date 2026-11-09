import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../models/world.dart';
import '../services/robot_service.dart';
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
    this.simulated = false,
    this.status = const RobotStatus(),
    this.objects = const [],
    this.savedPoints = const [],
    this.alerts = const [],
    this.unreadAlerts = 0,
    this.room = Room.standard,
  });

  final bool connected;
  final bool simulated;
  final RobotStatus status;
  final List<DetectedObject> objects;
  final List<SavedPoint> savedPoints;
  final List<AlertEntry> alerts;
  final int unreadAlerts;
  final Room room;

  RobotSession copyWith({
    bool? connected,
    RobotStatus? status,
    List<DetectedObject>? objects,
    List<SavedPoint>? savedPoints,
    List<AlertEntry>? alerts,
    int? unreadAlerts,
  }) =>
      RobotSession(
        connected: connected ?? this.connected,
        simulated: simulated,
        status: status ?? this.status,
        objects: objects ?? this.objects,
        savedPoints: savedPoints ?? this.savedPoints,
        alerts: alerts ?? this.alerts,
        unreadAlerts: unreadAlerts ?? this.unreadAlerts,
        room: room,
      );
}

class RobotController extends Notifier<RobotSession> {
  RobotService? _service;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  RobotSession build() {
    ref.onDispose(_teardown);
    return const RobotSession();
  }

  SimulatedRobotService? get simulator =>
      _service is SimulatedRobotService ? _service as SimulatedRobotService : null;

  Future<void> connectSimulated() => _connect(SimulatedRobotService(), true);

  Future<void> connectReal(String host, {int port = 81}) =>
      _connect(WebSocketRobotService(Uri.parse('ws://$host:$port')), false);

  Future<void> _connect(RobotService service, bool simulated) async {
    await _teardown();
    _service = service;
    final savedPoints = state.savedPoints;
    state = RobotSession(simulated: simulated, savedPoints: savedPoints);
    _subs
      ..add(service.statusStream.listen((s) => state = state.copyWith(status: s)))
      ..add(service.connectedStream.listen((c) => state = state.copyWith(connected: c)))
      ..add(service.eventStream.listen(_addAlert))
      ..add(service.objectStream.listen(_onObject));
    await service.connect();
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

  void calibrate() => _service?.send(RobotCommand.calibrate);
  void goTo(Offset p) => _service?.send(RobotCommand.goTo(p.dx, p.dy));
  void unload() => _service?.send(RobotCommand.unload);
  void emergencyStop() => _service?.send(RobotCommand.stop);
  void reset() => _service?.send(RobotCommand.reset);

  void savePoint(String name, Offset p) => state = state.copyWith(
      savedPoints: [...state.savedPoints, SavedPoint(name, p.dx, p.dy)]);

  void deletePoint(SavedPoint p) => state = state.copyWith(
      savedPoints: state.savedPoints.where((s) => s != p).toList());

  Future<void> disconnect() async {
    await _teardown();
    state = RobotSession(savedPoints: state.savedPoints);
  }

  Future<void> _teardown() async {
    // El servicio se detiene primero (de forma síncrona cancela sus temporizadores).
    final disposing = _service?.dispose();
    _service = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await disposing;
  }
}

final robotProvider =
    NotifierProvider<RobotController, RobotSession>(RobotController.new);
