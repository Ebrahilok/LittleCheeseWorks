import 'dart:convert';
import 'dart:ui';

import 'world.dart';

/// Estados del robot de transporte de carga.
enum RobotState {
  esperandoCarga('ESPERANDO_CARGA', 'Esperando carga en la base'),
  listo('LISTO', 'Listo'),
  enRuta('EN_RUTA', 'En ruta'),
  obstaculo('OBSTACULO', 'Obstáculo detectado'),
  entregando('ENTREGANDO', 'Esperando retiro de la carga'),
  regresando('REGRESANDO', 'Regresando a la base'),
  error('ERROR', 'Error'),
  paro('PARO', 'Paro de emergencia');

  const RobotState(this.wire, this.label);

  /// Valor que viaja en el protocolo JSON.
  final String wire;

  /// Texto para mostrar al usuario.
  final String label;

  static RobotState fromWire(String? value) => RobotState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => RobotState.error,
      );

  bool get isFault => this == error || this == paro;
  bool get isMoving => this == enRuta || this == regresando;
}

/// Estado reportado por el robot.
/// {"state","x","y","heading","load","calibrated","battery","obstacle","target":{"x","y"}}
class RobotStatus {
  const RobotStatus({
    this.state = RobotState.esperandoCarga,
    this.x = 0,
    this.y = 0,
    this.heading = 0,
    this.hasLoad = false,
    this.calibrated = false,
    this.target,
    this.battery = 100,
    this.obstacle = false,
  });

  final RobotState state;
  final double x, y;

  /// Orientación en radianes (0 = +x, sentido hacia +y).
  final double heading;
  final bool hasLoad;
  final bool calibrated;
  final Offset? target;
  final int battery;
  final bool obstacle;

  Offset get position => Offset(x, y);

  RobotStatus copyWith({
    RobotState? state,
    double? x,
    double? y,
    double? heading,
    bool? hasLoad,
    bool? calibrated,
    Offset? target,
    bool clearTarget = false,
    int? battery,
    bool? obstacle,
  }) =>
      RobotStatus(
        state: state ?? this.state,
        x: x ?? this.x,
        y: y ?? this.y,
        heading: heading ?? this.heading,
        hasLoad: hasLoad ?? this.hasLoad,
        calibrated: calibrated ?? this.calibrated,
        target: clearTarget ? null : (target ?? this.target),
        battery: battery ?? this.battery,
        obstacle: obstacle ?? this.obstacle,
      );

  factory RobotStatus.fromJson(Map<String, dynamic> json) {
    final t = json['target'];
    return RobotStatus(
      state: RobotState.fromWire(json['state'] as String?),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      hasLoad: json['load'] as bool? ?? false,
      calibrated: json['calibrated'] as bool? ?? false,
      target: t is Map
          ? Offset((t['x'] as num).toDouble(), (t['y'] as num).toDouble())
          : null,
      battery: (json['battery'] as num?)?.toInt() ?? 0,
      obstacle: json['obstacle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'state': state.wire,
        'x': x,
        'y': y,
        'heading': heading,
        'load': hasLoad,
        'calibrated': calibrated,
        if (target != null) 'target': {'x': target!.dx, 'y': target!.dy},
        'battery': battery,
        'obstacle': obstacle,
      };
}

/// Evento del robot: {"event":"error","code":"LINE_LOST"}.
class RobotEvent {
  const RobotEvent(this.code, {this.detail, DateTime? at}) : _at = at;

  final String code;
  final String? detail;
  final DateTime? _at;
  DateTime get at => _at ?? DateTime.now();

  static const localizationLost = 'LOCALIZATION_LOST';
  static const lowBattery = 'LOW_BATTERY';
  static const obstacleTimeout = 'OBSTACLE_TIMEOUT';
  static const connectionLost = 'CONNECTION_LOST';
  static const objectDetected = 'OBJECT_DETECTED';

  String get description {
    switch (code) {
      case localizationLost:
        return 'El robot perdió su ubicación';
      case lowBattery:
        return 'Batería baja';
      case obstacleTimeout:
        return 'Obstáculo prolongado (más de 30 s)';
      case connectionLost:
        return 'Se perdió la conexión con el robot';
      case objectDetected:
        return 'Objeto detectado${detail != null ? ' en $detail' : ''}';
      default:
        return 'Falla: $code';
    }
  }
}

/// Detección o desaparición de un objeto en el cuarto.
class ObjectEvent {
  const ObjectEvent.seen(DetectedObject this.object)
      : id = -1,
        removed = false;
  const ObjectEvent.gone(this.id)
      : object = null,
        removed = true;

  final DetectedObject? object;
  final int id;
  final bool removed;

  int get objectId => object?.id ?? id;
}

/// Comandos App → Robot.
class RobotCommand {
  const RobotCommand._(this.cmd, {this.x, this.y});

  /// El objeto fue colocado en la base: el robot fija ese punto como origen (0,0).
  static const calibrate = RobotCommand._('calibrate');
  factory RobotCommand.goTo(double x, double y) =>
      RobotCommand._('goto', x: x, y: y);

  /// La carga fue retirada en el destino.
  static const unload = RobotCommand._('unload');
  static const stop = RobotCommand._('stop');
  static const reset = RobotCommand._('reset');

  final String cmd;
  final double? x, y;

  Map<String, dynamic> toJson() =>
      {'cmd': cmd, if (x != null) 'x': x, if (y != null) 'y': y};

  String encode() => jsonEncode(toJson());
}

/// Mensaje decodificado Robot → App.
class RobotMessage {
  const RobotMessage({this.status, this.event, this.object});
  final RobotStatus? status;
  final RobotEvent? event;
  final ObjectEvent? object;

  /// Devuelve null si el texto no es JSON válido o no es un mensaje conocido.
  static RobotMessage? tryParse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      if (json.containsKey('state')) {
        return RobotMessage(status: RobotStatus.fromJson(json));
      }
      switch (json['event']) {
        case 'error':
          if (json['code'] is String) {
            return RobotMessage(event: RobotEvent(json['code'] as String));
          }
        case 'object':
          return RobotMessage(
              object: ObjectEvent.seen(DetectedObject.fromJson(json)));
        case 'object_gone':
          return RobotMessage(
              object: ObjectEvent.gone((json['id'] as num).toInt()));
      }
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
