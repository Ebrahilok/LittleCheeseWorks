import type { Comando, MensajeRobot } from './modelo';

export interface OyentesRobot {
  alMensaje: (m: MensajeRobot) => void;
  alCambiarConexion: (conectado: boolean) => void;
}

/** Misma interfaz para el robot real (WebSocket) y para el simulador. */
export interface RobotService {
  conectar(): Promise<void>;
  enviar(comando: Comando): void;
  cerrar(): void;
}
