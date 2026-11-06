import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/robot_state.dart';
import 'robot_service.dart';

/// Cliente WebSocket hacia el ESP32 (servidor WebSocket, especificación §4.1).
class WebSocketRobotService implements RobotService {
  WebSocketRobotService(this.uri, {this.silenceTimeout = const Duration(seconds: 5)});

  final Uri uri;

  /// Sin mensajes durante este tiempo se considera perdida la comunicación.
  final Duration silenceTimeout;

  final _status = StreamController<RobotStatus>.broadcast();
  final _events = StreamController<RobotEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _watchdog;

  @override
  Stream<RobotStatus> get statusStream => _status.stream;
  @override
  Stream<RobotEvent> get eventStream => _events.stream;
  @override
  Stream<bool> get connectedStream => _connected.stream;

  @override
  Future<void> connect() async {
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    await channel.ready; // lanza si no hay conexión
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
  }

  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(silenceTimeout, _lost);
  }

  void _lost() {
    _watchdog?.cancel();
    if (_connected.isClosed) return;
    _connected.add(false);
    _events.add(const RobotEvent(RobotEvent.connectionLost));
  }

  @override
  void send(RobotCommand command) => _channel?.sink.add(command.encode());

  @override
  Future<void> dispose() async {
    _watchdog?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _status.close();
    await _events.close();
    await _connected.close();
  }
}
