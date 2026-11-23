import { EVENTOS, leerMensaje } from './modelo';
import type { Comando } from './modelo';
import type { OyentesRobot, RobotService } from './RobotService';

// Cliente WebSocket hacia el ESP32 (ws://IP:81).
// Si la conexión se cae después de abrirse, avisa una vez y reintenta sola
// cada 1, 2, 4 y hasta 8 segundos hasta recuperar al robot o hasta cerrar.
const SILENCIO_MS = 5000;
const REINTENTO_MS = 1000;
const REINTENTO_MAX_MS = 8000;

export class RobotWebSocket implements RobotService {
  private ws: WebSocket | null = null;
  private vigilante: ReturnType<typeof setTimeout> | null = null;
  private reintento: ReturnType<typeof setTimeout> | null = null;
  private fallos = 0;
  private arriba = false;
  private cerrado = false;

  private url: string;
  private oyentes: OyentesRobot;

  constructor(url: string, oyentes: OyentesRobot) {
    this.url = url;
    this.oyentes = oyentes;
  }

  /** Falla si el primer intento no conecta (IP mala o robot apagado). */
  conectar(): Promise<void> {
    return this.abrir();
  }

  private abrir(): Promise<void> {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(this.url);
      let abierto = false;
      const tiempo = setTimeout(() => {
        if (!abierto) {
          ws.close();
          reject(new Error('El robot no respondió.'));
        }
      }, SILENCIO_MS);

      ws.onopen = () => {
        abierto = true;
        clearTimeout(tiempo);
        if (this.cerrado) {
          ws.close();
          return resolve();
        }
        this.ws = ws;
        this.arriba = true;
        this.fallos = 0;
        this.oyentes.alCambiarConexion(true);
        this.reiniciarVigilante();
        resolve();
      };
      ws.onmessage = (e) => {
        this.reiniciarVigilante();
        const m = leerMensaje(String(e.data));
        if (m) this.oyentes.alMensaje(m);
      };
      ws.onerror = () => {
        if (!abierto) {
          clearTimeout(tiempo);
          reject(new Error('No se pudo abrir la conexión.'));
        } else this.perdida();
      };
      ws.onclose = () => {
        if (abierto) this.perdida();
      };
    });
  }

  private reiniciarVigilante() {
    if (this.vigilante) clearTimeout(this.vigilante);
    this.vigilante = setTimeout(() => this.perdida(), SILENCIO_MS);
  }

  private perdida() {
    // Puede llegar varias veces por la misma caída (error, cierre o silencio)
    if (this.cerrado || !this.arriba) return;
    this.arriba = false;
    if (this.vigilante) clearTimeout(this.vigilante);
    this.ws?.close();
    this.ws = null;
    this.oyentes.alCambiarConexion(false);
    this.oyentes.alMensaje({ tipo: 'evento', evento: { codigo: EVENTOS.conexionPerdida, fecha: Date.now() } });
    this.programarReintento();
  }

  private programarReintento() {
    if (this.cerrado || this.reintento) return;
    const espera = Math.min(REINTENTO_MS * 2 ** Math.min(this.fallos, 6), REINTENTO_MAX_MS);
    this.reintento = setTimeout(async () => {
      this.reintento = null;
      try {
        await this.abrir();
      } catch {
        this.fallos++;
        this.programarReintento();
      }
    }, espera);
  }

  /** Sin conexión el comando se descarta: el firmware frena solo al perder a la app. */
  enviar(c: Comando) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) this.ws.send(JSON.stringify(c));
  }

  cerrar() {
    this.cerrado = true;
    if (this.vigilante) clearTimeout(this.vigilante);
    if (this.reintento) clearTimeout(this.reintento);
    this.ws?.close();
    this.ws = null;
  }
}
