import '../models/robot_state.dart';

/// Contrato común entre el robot real (WebSocket) y el simulado.
abstract class RobotService {
  Stream<RobotStatus> get statusStream;
  Stream<RobotEvent> get eventStream;
  Stream<ObjectEvent> get objectStream;
  Stream<bool> get connectedStream;

  Future<void> connect();
  void send(RobotCommand command);
  Future<void> dispose();
}
