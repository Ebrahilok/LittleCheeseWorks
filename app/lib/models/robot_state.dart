import 'dart:convert';

/// Estados de la máquina de estados del robot (especificación §4.2).
enum RobotState {
  reposo('REPOSO', 'En reposo'),
  enRuta('EN_RUTA', 'En ruta'),
  obstaculo('OBSTACULO', 'Obstáculo detectado'),
  esperando('ESPERANDO', 'Esperando confirmación'),
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
}

/// Estado reportado por el robot: {"state","table","battery","obstacle"}.
class RobotStatus {
  const RobotStatus({
    this.state = RobotState.reposo,
    this.table,
    this.battery = 100,
    this.obstacle = false,
  });

  final RobotState state;
  final int? table;
  final int battery;
  final bool obstacle;

  RobotStatus copyWith({
    RobotState? state,
    int? table,
    bool clearTable = false,
    int? battery,
    bool? obstacle,
  }) =>
      RobotStatus(
        state: state ?? this.state,
        table: clearTable ? null : (table ?? this.table),
        battery: battery ?? this.battery,
        obstacle: obstacle ?? this.obstacle,
      );

  factory RobotStatus.fromJson(Map<String, dynamic> json) => RobotStatus(
        state: RobotState.fromWire(json['state'] as String?),
        table: json['table'] as int?,
        battery: (json['battery'] as num?)?.toInt() ?? 0,
        obstacle: json['obstacle'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'state': state.wire,
        if (table != null) 'table': table,
        'battery': battery,
        'obstacle': obstacle,
      };
}

/// Evento del robot: {"event":"error","code":"LINE_LOST"}.
class RobotEvent {
  const RobotEvent(this.code, {DateTime? at}) : _at = at;

  final String code;
  final DateTime? _at;
  DateTime get at => _at ?? DateTime.now();

  static const lineLost = 'LINE_LOST';
  static const lowBattery = 'LOW_BATTERY';
  static const obstacleTimeout = 'OBSTACLE_TIMEOUT';
  static const connectionLost = 'CONNECTION_LOST';

  String get description {
    switch (code) {
      case lineLost:
        return 'El robot perdió la línea';
      case lowBattery:
        return 'Batería baja';
      case obstacleTimeout:
        return 'Obstáculo prolongado (más de 30 s)';
      case connectionLost:
        return 'Se perdió la conexión con el robot';
      default:
        return 'Falla: $code';
    }
  }
}

/// Comandos App → Robot (especificación §4.3).
class RobotCommand {
  const RobotCommand._(this.cmd, [this.table]);

  factory RobotCommand.go(int table) => RobotCommand._('go', table);
  static const confirm = RobotCommand._('confirm');
  static const stop = RobotCommand._('stop');
  static const reset = RobotCommand._('reset');

  final String cmd;
  final int? table;

  Map<String, dynamic> toJson() => {'cmd': cmd, if (table != null) 'table': table};

  String encode() => jsonEncode(toJson());
}

/// Mensaje decodificado Robot → App: estado o evento.
class RobotMessage {
  const RobotMessage({this.status, this.event});
  final RobotStatus? status;
  final RobotEvent? event;

  /// Devuelve null si el texto no es JSON válido o no es un mensaje conocido.
  static RobotMessage? tryParse(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      if (json.containsKey('state')) {
        return RobotMessage(status: RobotStatus.fromJson(json));
      }
      if (json['event'] == 'error' && json['code'] is String) {
        return RobotMessage(event: RobotEvent(json['code'] as String));
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
