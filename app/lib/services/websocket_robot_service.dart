import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/robot_state.dart';
import 'robot_service.dart';

/// Cliente WebSocket hacia el ESP32 (servidor WebSocket, especificación §4.1).
///
/// Si la conexión se cae después de haberse establecido, avisa una vez
/// (`connectedStream` = false y evento CONNECTION_LOST) y reintenta sola hasta
/// que vuelva o se llame a [dispose].
class WebSocketRobotService implements RobotService {
  WebSocketRobotService(
    this.uri, {
    this.silenceTimeout = const Duration(seconds: 5),
    this.reconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 8),
  });

  final Uri uri;

  /// Sin mensajes durante este tiempo se considera perdida la comunicación.
  final Duration silenceTimeout;

  /// Espera antes del primer reintento; se duplica en cada fallo hasta
  /// [maxReconnectDelay].
  final Duration reconnectDelay;
  final Duration maxReconnectDelay;

  final _status = StreamController<RobotStatus>.broadcast();
  final _events = StreamController<RobotEvent>.broadcast();
  final _objects = StreamController<ObjectEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _watchdog;
  Timer? _retry;
  int _failedAttempts = 0;
  bool _up = false;
  bool _disposed = false;

  @override
  Stream<RobotStatus> get statusStream => _status.stream;
  @override
  Stream<RobotEvent> get eventStream => _events.stream;
  @override
  Stream<ObjectEvent> get objectStream => _objects.stream;
  @override
  Stream<bool> get connectedStream => _connected.stream;

  /// Lanza si el primer intento falla (IP incorrecta, robot apagado).
  @override
  Future<void> connect() => _open();

  Future<void> _open() async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready; // lanza si no hay conexión
    if (_disposed) {
      unawaited(channel.sink.close());
      return;
    }
    _channel = channel;
    _up = true;
    _failedAttempts = 0;
    _connected.add(true);
    _resetWatchdog();
    _sub = channel.stream.listen(
      _onData,
      onError: (_) => _lost(),
      onDone: _lost,
    );
  }

  void _onData(dynamic data) {
    _resetWatchdog();
    final msg = RobotMessage.tryParse(data.toString());
    if (msg?.status != null) _status.add(msg!.status!);
    if (msg?.event != null) _events.add(msg!.event!);
    if (msg?.object != null) _objects.add(msg!.object!);
  }

  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(silenceTimeout, _lost);
  }

  void _lost() {
    // Puede llegar varias veces por la misma caída (error, cierre, silencio).
    if (_disposed || !_up) return;
    _up = false;
    _watchdog?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_channel?.sink.close());
    _channel = null;
    _connected.add(false);
    _events.add(const RobotEvent(RobotEvent.connectionLost));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _retry != null) return;
    var delay = reconnectDelay * (1 << _failedAttempts.clamp(0, 6));
    if (delay > maxReconnectDelay) delay = maxReconnectDelay;
    _retry = Timer(delay, () async {
      _retry = null;
      try {
        await _open();
      } catch (_) {
        _failedAttempts++;
        _scheduleReconnect();
      }
    });
  }

  /// Sin conexión el comando se descarta: el firmware detiene los motores por
  /// su cuenta cuando deja de recibir a la app.
  @override
  void send(RobotCommand command) => _channel?.sink.add(command.encode());

  @override
  Future<void> dispose() async {
    _disposed = true;
    _watchdog?.cancel();
    _retry?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _status.close();
    await _events.close();
    await _objects.close();
    await _connected.close();
  }
}
