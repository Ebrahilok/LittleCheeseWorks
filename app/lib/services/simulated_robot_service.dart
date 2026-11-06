import 'dart:async';

import '../models/robot_state.dart';
import 'robot_service.dart';

/// Robot simulado: reproduce la máquina de estados de la especificación §4.2.
/// Los tiempos son configurables para poder probarlo rápido.
class SimulatedRobotService implements RobotService {
  SimulatedRobotService({
    this.travelTime = const Duration(seconds: 8),
    this.waitTimeout = const Duration(seconds: 60),
    this.obstacleTimeout = const Duration(seconds: 30),
    this.tick = const Duration(seconds: 1),
  });

  final Duration travelTime;
  final Duration waitTimeout;
  final Duration obstacleTimeout;
  final Duration tick;

  final _status = StreamController<RobotStatus>.broadcast();
  final _events = StreamController<RobotEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  RobotStatus _current = const RobotStatus();
  RobotState? _stateBeforeObstacle;
  Timer? _ticker;
  Timer? _phaseTimer;
  Timer? _obstacleTimer;
  int _ticks = 0;
  bool _lowBatteryNotified = false;

  @override
  Stream<RobotStatus> get statusStream => _status.stream;
  @override
  Stream<RobotEvent> get eventStream => _events.stream;
  @override
  Stream<bool> get connectedStream => _connected.stream;

  RobotStatus get current => _current;

  @override
  Future<void> connect() async {
    _connected.add(true);
    _emit(_current);
    _ticker = Timer.periodic(tick, (_) => _onTick());
  }

  @override
  void send(RobotCommand command) {
    switch (command.cmd) {
      case 'go':
        if (_current.state == RobotState.reposo && command.table != null) {
          _startPhase(RobotState.enRuta, table: command.table);
        }
      case 'confirm':
        if (_current.state == RobotState.esperando) {
          _startPhase(RobotState.regresando);
        }
      case 'stop':
        _cancelTimers();
        _emit(_current.copyWith(state: RobotState.paro, obstacle: false));
      case 'reset':
        if (_current.state.isFault) {
          _cancelTimers();
          _emit(_current.copyWith(
              state: RobotState.reposo, clearTable: true, obstacle: false));
        }
    }
  }

  /// Simula un objeto frente al robot (RF-02).
  void placeObstacle() {
    final s = _current.state;
    if (s != RobotState.enRuta && s != RobotState.regresando) return;
    _phaseTimer?.cancel();
    _stateBeforeObstacle = s;
    _emit(_current.copyWith(state: RobotState.obstaculo, obstacle: true));
    _obstacleTimer = Timer(obstacleTimeout, () {
      _events.add(const RobotEvent(RobotEvent.obstacleTimeout));
      _emit(_current.copyWith(state: RobotState.error, obstacle: false));
    });
  }

  /// Retira el objeto: el robot reanuda la marcha (RF-03).
  void clearObstacle() {
    if (_current.state != RobotState.obstaculo) return;
    _obstacleTimer?.cancel();
    _startPhase(_stateBeforeObstacle ?? RobotState.enRuta, keepTable: true);
  }

  /// Simula pérdida de línea (RF-09).
  void loseLine() {
    final s = _current.state;
    if (s != RobotState.enRuta && s != RobotState.regresando) return;
    _cancelTimers();
    _events.add(const RobotEvent(RobotEvent.lineLost));
    _emit(_current.copyWith(state: RobotState.error));
  }

  void _startPhase(RobotState state, {int? table, bool keepTable = false}) {
    _phaseTimer?.cancel();
    final duration = state == RobotState.esperando ? waitTimeout : travelTime;
    _emit(_current.copyWith(
      state: state,
      table: table,
      clearTable: !keepTable && table == null && state == RobotState.reposo,
      obstacle: false,
    ));
    _phaseTimer = Timer(duration, () => _phaseDone(state));
  }

  void _phaseDone(RobotState state) {
    switch (state) {
      case RobotState.enRuta:
        _startPhase(RobotState.esperando, keepTable: true);
      case RobotState.esperando:
        _startPhase(RobotState.regresando, keepTable: true);
      case RobotState.regresando:
        _emit(_current.copyWith(
            state: RobotState.reposo, clearTable: true, obstacle: false));
      default:
        break;
    }
  }

  void _onTick() {
    _ticks++;
    var battery = _current.battery;
    final moving = _current.state == RobotState.enRuta ||
        _current.state == RobotState.regresando;
    if (moving && _ticks % 5 == 0 && battery > 0) battery--;
    if (battery <= 20 && !_lowBatteryNotified) {
      _lowBatteryNotified = true;
      _events.add(const RobotEvent(RobotEvent.lowBattery));
    }
    _emit(_current.copyWith(battery: battery));
  }

  void _cancelTimers() {
    _phaseTimer?.cancel();
    _obstacleTimer?.cancel();
  }

  void _emit(RobotStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _cancelTimers();
    await _status.close();
    await _events.close();
    await _connected.close();
  }
}
