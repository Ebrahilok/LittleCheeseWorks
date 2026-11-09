import 'dart:async';
import 'dart:math';
import 'dart:ui';

import '../models/robot_state.dart';
import '../models/world.dart';
import 'robot_service.dart';

/// Robot simulado: cinemática simple (gira hacia el destino y avanza en línea
/// recta), detección de objetos por radio de sensor y parada ante obstáculos.
class SimulatedRobotService implements RobotService {
  SimulatedRobotService({
    this.tick = const Duration(milliseconds: 100),
    this.speed = 0.5,
    this.turnRate = 2.5,
    this.sensorRange = 1.2,
    this.stopDistance = 0.5,
    this.unloadTimeout = const Duration(seconds: 60),
    this.obstacleTimeout = const Duration(seconds: 30),
    this.room = Room.standard,
  });

  final Duration tick;

  /// m/s
  final double speed;

  /// rad/s
  final double turnRate;
  final double sensorRange;
  final double stopDistance;
  final Duration unloadTimeout;
  final Duration obstacleTimeout;
  final Room room;

  static const _arrivalRadius = 0.05;
  static const _robotHalfWidth = 0.2;

  final _statusCtl = StreamController<RobotStatus>.broadcast();
  final _eventCtl = StreamController<RobotEvent>.broadcast();
  final _objectCtl = StreamController<ObjectEvent>.broadcast();
  final _connectedCtl = StreamController<bool>.broadcast();

  RobotStatus _status = const RobotStatus();
  final Map<int, DetectedObject> _world = {};
  final Set<int> _known = {};
  int _nextId = 1;
  RobotState _stateBeforeObstacle = RobotState.enRuta;
  Duration _stateTime = Duration.zero;
  double _battery = 100;
  bool _lowBatteryNotified = false;
  Timer? _ticker;

  @override
  Stream<RobotStatus> get statusStream => _statusCtl.stream;
  @override
  Stream<RobotEvent> get eventStream => _eventCtl.stream;
  @override
  Stream<ObjectEvent> get objectStream => _objectCtl.stream;
  @override
  Stream<bool> get connectedStream => _connectedCtl.stream;

  RobotStatus get current => _status;
  List<DetectedObject> get worldObjects => _world.values.toList();

  @override
  Future<void> connect() async {
    _connectedCtl.add(true);
    _emit(_status);
    _ticker = Timer.periodic(tick, (_) => _onTick());
  }

  @override
  void send(RobotCommand c) {
    switch (c.cmd) {
      case 'calibrate':
        // El objeto está en la base: ese punto es el origen.
        if (_status.state == RobotState.esperandoCarga) {
          _setState(_status.copyWith(
            state: RobotState.listo,
            x: 0,
            y: 0,
            heading: 0,
            hasLoad: true,
            calibrated: true,
            clearTarget: true,
          ));
        }
      case 'goto':
        // Si el robot está calibrado y sin falla se le puede (re)dirigir en
        // cualquier momento, con o sin carga, sin tener que parar el robot.
        final canRedirect = _status.calibrated && !_status.state.isFault;
        if (canRedirect && c.x != null && c.y != null) {
          final t = room.clamp(Offset(c.x!, c.y!));
          _setState(_status.copyWith(
              state: RobotState.enRuta, target: t, obstacle: false));
        }
      case 'unload':
        if (_status.state == RobotState.entregando) _beginReturn();
      case 'stop':
        _setState(_status.copyWith(state: RobotState.paro, obstacle: false));
      case 'reset':
        if (_status.state.isFault) {
          _setState(_status.copyWith(
            state: _status.calibrated ? RobotState.listo : RobotState.esperandoCarga,
            clearTarget: true,
            obstacle: false,
          ));
        }
    }
  }

  // ---- Controles de simulación -------------------------------------------

  /// Coloca un objeto en el cuarto. Devuelve su id.
  int placeObject(double x, double y, {double size = 0.3}) {
    final id = _nextId++;
    _world[id] = DetectedObject(id: id, x: x, y: y, w: size, h: size);
    return id;
  }

  void removeObject(int id) => _world.remove(id);

  void removeLastObject() {
    if (_world.isEmpty) return;
    _world.remove(_world.keys.reduce(max));
  }

  /// Simula que el robot pierde su ubicación.
  void loseLocalization() {
    if (!_status.state.isMoving) return;
    _eventCtl.add(const RobotEvent(RobotEvent.localizationLost));
    _setState(_status.copyWith(state: RobotState.error, calibrated: false));
  }

  // ---- Lógica -------------------------------------------------------------

  void _beginReturn() => _setState(_status.copyWith(
        state: RobotState.regresando,
        hasLoad: false,
        target: Offset.zero,
      ));

  void _setState(RobotStatus s) {
    if (s.state != _status.state) _stateTime = Duration.zero;
    _emit(s);
  }

  void _onTick() {
    final dt = tick.inMicroseconds / 1e6;
    _stateTime += tick;
    switch (_status.state) {
      case RobotState.enRuta:
      case RobotState.regresando:
        _drive(dt);
      case RobotState.obstaculo:
        if (!_pathBlocked()) {
          _setState(_status.copyWith(state: _stateBeforeObstacle, obstacle: false));
        } else if (_stateTime >= obstacleTimeout) {
          _eventCtl.add(const RobotEvent(RobotEvent.obstacleTimeout));
          _setState(_status.copyWith(state: RobotState.error, obstacle: false));
        }
      case RobotState.entregando:
        if (_stateTime >= unloadTimeout) _beginReturn();
      default:
        break;
    }
    _sense();
    if (_battery <= 20 && !_lowBatteryNotified) {
      _lowBatteryNotified = true;
      _eventCtl.add(const RobotEvent(RobotEvent.lowBattery));
    }
    _emit(_status);
  }

  void _drive(double dt) {
    final target = _status.target;
    if (target == null) return;
    final dx = target.dx - _status.x;
    final dy = target.dy - _status.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist <= _arrivalRadius) {
      _arrive();
      return;
    }
    // Girar hacia el destino.
    final desired = atan2(dy, dx);
    final err = _wrap(desired - _status.heading);
    final turn = err.clamp(-turnRate * dt, turnRate * dt);
    final heading = _status.heading + turn;
    if (err.abs() > 0.2) {
      _emit(_status.copyWith(heading: heading));
      return;
    }
    if (_pathBlocked()) {
      _stateBeforeObstacle = _status.state;
      _setState(_status.copyWith(state: RobotState.obstaculo, obstacle: true));
      return;
    }
    final step = min(speed * dt, dist);
    _battery = max(0, _battery - step * 0.5);
    _emit(_status.copyWith(
      heading: heading,
      x: _status.x + cos(heading) * step,
      y: _status.y + sin(heading) * step,
      battery: _battery.round(),
    ));
  }

  void _arrive() {
    if (_status.state == RobotState.enRuta) {
      // Sin carga no hay nada que entregar: queda listo en ese punto.
      _setState(_status.copyWith(
          state: _status.hasLoad ? RobotState.entregando : RobotState.listo,
          clearTarget: !_status.hasLoad));
    } else {
      _setState(_status.copyWith(
        state: RobotState.esperandoCarga,
        x: 0,
        y: 0,
        hasLoad: false,
        clearTarget: true,
      ));
    }
  }

  bool _pathBlocked() {
    final hx = cos(_status.heading), hy = sin(_status.heading);
    for (final o in _world.values) {
      final dx = o.x - _status.x, dy = o.y - _status.y;
      final forward = dx * hx + dy * hy;
      final lateral = (dx * hy - dy * hx).abs();
      if (forward > 0 &&
          forward - o.radius < stopDistance &&
          lateral < o.radius + _robotHalfWidth) {
        return true;
      }
    }
    return false;
  }

  void _sense() {
    for (final o in _world.values) {
      if (_known.contains(o.id)) continue;
      if ((o.position - _status.position).distance <= sensorRange) {
        _known.add(o.id);
        _objectCtl.add(ObjectEvent.seen(o));
      }
    }
    for (final id in _known.toList()) {
      if (!_world.containsKey(id)) {
        _known.remove(id);
        _objectCtl.add(ObjectEvent.gone(id));
      }
    }
  }

  static double _wrap(double a) {
    while (a > pi) {
      a -= 2 * pi;
    }
    while (a < -pi) {
      a += 2 * pi;
    }
    return a;
  }

  void _emit(RobotStatus s) {
    _status = s;
    if (!_statusCtl.isClosed) _statusCtl.add(s);
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    await _statusCtl.close();
    await _eventCtl.close();
    await _objectCtl.close();
    await _connectedCtl.close();
  }
}
