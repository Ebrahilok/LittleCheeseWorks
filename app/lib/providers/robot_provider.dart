import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
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
    this.alerts = const [],
    this.unreadAlerts = 0,
  });

  final bool connected;
  final bool simulated;
  final RobotStatus status;
  final List<AlertEntry> alerts;
  final int unreadAlerts;

  RobotSession copyWith({
    bool? connected,
    bool? simulated,
    RobotStatus? status,
    List<AlertEntry>? alerts,
    int? unreadAlerts,
  }) =>
      RobotSession(
        connected: connected ?? this.connected,
        simulated: simulated ?? this.simulated,
        status: status ?? this.status,
        alerts: alerts ?? this.alerts,
        unreadAlerts: unreadAlerts ?? this.unreadAlerts,
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
    _subs
      ..add(service.statusStream.listen((s) => state = state.copyWith(status: s)))
      ..add(service.connectedStream.listen((c) {
        state = state.copyWith(connected: c);
      }))
      ..add(service.eventStream.listen(_onEvent));
    state = RobotSession(simulated: simulated);
    await service.connect();
  }

  void _onEvent(RobotEvent e) {
    state = state.copyWith(
      alerts: [AlertEntry(e), ...state.alerts],
      unreadAlerts: state.unreadAlerts + 1,
    );
  }

  void markAlertsRead() => state = state.copyWith(unreadAlerts: 0);

  void sendToTable(int table) => _service?.send(RobotCommand.go(table));
  void confirmDelivery() => _service?.send(RobotCommand.confirm);
  void emergencyStop() => _service?.send(RobotCommand.stop);
  void reset() => _service?.send(RobotCommand.reset);

  Future<void> disconnect() async {
    await _teardown();
    state = const RobotSession();
  }

  Future<void> _teardown() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _service?.dispose();
    _service = null;
  }
}

final robotProvider =
    NotifierProvider<RobotController, RobotSession>(RobotController.new);
