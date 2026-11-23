import {
  ajustarAlCuarto, CUARTO_ESTANDAR, distancia, EVENTOS, esFalla, STATUS_INICIAL,
} from './modelo';
import type { Comando, Cuarto, EstadoRobot, ObjetoDetectado, StatusRobot } from './modelo';
import type { OyentesRobot, RobotService } from './RobotService';

// Robot simulado: gira hacia el destino, avanza en línea recta, detecta objetos
// dentro del alcance del sensor y se detiene si uno le estorba.
const LLEGADA = 0.05;
const MEDIO_ANCHO = 0.2;

export interface OpcionesSimulador {
  tickMs?: number;
  velocidad?: number; // m/s
  giro?: number; // rad/s
  alcanceSensor?: number;
  distanciaParo?: number;
  esperaRetiroMs?: number;
  esperaObstaculoMs?: number;
}

export class RobotSimulado implements RobotService {
  cuarto: Cuarto;
  private st: StatusRobot = { ...STATUS_INICIAL };
  private mundo = new Map<number, ObjetoDetectado>();
  private conocidos = new Set<number>();
  private siguienteId = 1;
  private estadoAntesObstaculo: EstadoRobot = 'EN_RUTA';
  private tiempoEnEstado = 0;
  private bateria = 100;
  private avisoBateria = false;
  private timer: ReturnType<typeof setInterval> | null = null;
  private o: Required<OpcionesSimulador>;
  private oyentes: OyentesRobot;

  constructor(oyentes: OyentesRobot, cuarto: Cuarto = CUARTO_ESTANDAR, opciones: OpcionesSimulador = {}) {
    this.oyentes = oyentes;
    this.cuarto = cuarto;
    this.o = {
      tickMs: 100, velocidad: 0.5, giro: 2.5, alcanceSensor: 1.2, distanciaParo: 0.5,
      esperaRetiroMs: 60_000, esperaObstaculoMs: 30_000, ...opciones,
    };
  }

  get status() {
    return this.st;
  }

  async conectar() {
    this.oyentes.alCambiarConexion(true);
    this.emitir(this.st);
    this.timer = setInterval(() => this.paso(), this.o.tickMs);
  }

  cerrar() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  enviar(c: Comando) {
    switch (c.cmd) {
      case 'calibrate':
        // La carga está en la base: ese punto es el origen
        if (this.st.estado === 'ESPERANDO_CARGA') {
          this.cambiar({ ...this.st, estado: 'LISTO', x: 0, y: 0, rumbo: 0, conCarga: true, calibrado: true, destino: null });
        }
        break;
      case 'goto':
        // Calibrado y sin falla se puede mandar a otro punto en cualquier momento
        if (this.st.calibrado && !esFalla(this.st.estado)) {
          const destino = ajustarAlCuarto(this.cuarto, { x: c.x, y: c.y });
          this.cambiar({ ...this.st, estado: 'EN_RUTA', destino, obstaculo: false });
        }
        break;
      case 'unload':
        if (this.st.estado === 'ENTREGANDO') this.regresar();
        break;
      case 'stop':
        this.cambiar({ ...this.st, estado: 'PARO', obstaculo: false });
        break;
      case 'reset':
        if (esFalla(this.st.estado)) {
          this.cambiar({ ...this.st, estado: this.st.calibrado ? 'LISTO' : 'ESPERANDO_CARGA', destino: null, obstaculo: false });
        }
        break;
    }
  }

  // ---- Controles que solo existen en la simulación ----
  colocarObjeto(x: number, y: number, tam = 0.3): number {
    const id = this.siguienteId++;
    this.mundo.set(id, { id, x, y, w: tam, h: tam });
    return id;
  }

  quitarUltimoObjeto() {
    if (this.mundo.size === 0) return;
    this.mundo.delete(Math.max(...this.mundo.keys()));
  }

  perderUbicacion() {
    if (this.st.estado !== 'EN_RUTA' && this.st.estado !== 'REGRESANDO') return;
    this.evento(EVENTOS.ubicacionPerdida);
    this.cambiar({ ...this.st, estado: 'ERROR', calibrado: false });
  }

  // ---- Lógica ----
  /** Avanza la simulación un tick. Es pública para poder probarla sin temporizador. */
  paso() {
    const dt = this.o.tickMs / 1000;
    this.tiempoEnEstado += this.o.tickMs;
    switch (this.st.estado) {
      case 'EN_RUTA':
      case 'REGRESANDO':
        this.manejar(dt);
        break;
      case 'OBSTACULO':
        if (!this.caminoBloqueado()) {
          this.cambiar({ ...this.st, estado: this.estadoAntesObstaculo, obstaculo: false });
        } else if (this.tiempoEnEstado >= this.o.esperaObstaculoMs) {
          this.evento(EVENTOS.obstaculoProlongado);
          this.cambiar({ ...this.st, estado: 'ERROR', obstaculo: false });
        }
        break;
      case 'ENTREGANDO':
        if (this.tiempoEnEstado >= this.o.esperaRetiroMs) this.regresar();
        break;
    }
    this.sensar();
    if (this.bateria <= 20 && !this.avisoBateria) {
      this.avisoBateria = true;
      this.evento(EVENTOS.bateriaBaja);
    }
    this.emitir(this.st);
  }

  private manejar(dt: number) {
    const d = this.st.destino;
    if (!d) return;
    const dx = d.x - this.st.x;
    const dy = d.y - this.st.y;
    const dist = Math.hypot(dx, dy);
    if (dist <= LLEGADA) {
      this.llegar();
      return;
    }
    const error = envolver(Math.atan2(dy, dx) - this.st.rumbo);
    const giro = Math.max(-this.o.giro * dt, Math.min(this.o.giro * dt, error));
    const rumbo = this.st.rumbo + giro;
    if (Math.abs(error) > 0.2) {
      this.st = { ...this.st, rumbo };
      return;
    }
    if (this.caminoBloqueado()) {
      this.estadoAntesObstaculo = this.st.estado;
      this.cambiar({ ...this.st, estado: 'OBSTACULO', obstaculo: true });
      return;
    }
    const avance = Math.min(this.o.velocidad * dt, dist);
    this.bateria = Math.max(0, this.bateria - avance * 0.5);
    this.st = {
      ...this.st,
      rumbo,
      x: this.st.x + Math.cos(rumbo) * avance,
      y: this.st.y + Math.sin(rumbo) * avance,
      bateria: Math.round(this.bateria),
    };
  }

  private llegar() {
    if (this.st.estado === 'EN_RUTA') {
      // Sin carga no hay nada que entregar: se queda listo en ese punto
      this.cambiar(this.st.conCarga
        ? { ...this.st, estado: 'ENTREGANDO' }
        : { ...this.st, estado: 'LISTO', destino: null });
    } else {
      this.cambiar({ ...this.st, estado: 'ESPERANDO_CARGA', x: 0, y: 0, conCarga: false, destino: null });
    }
  }

  private regresar() {
    this.cambiar({ ...this.st, estado: 'REGRESANDO', conCarga: false, destino: { x: 0, y: 0 } });
  }

  private caminoBloqueado(): boolean {
    const hx = Math.cos(this.st.rumbo);
    const hy = Math.sin(this.st.rumbo);
    for (const o of this.mundo.values()) {
      const dx = o.x - this.st.x;
      const dy = o.y - this.st.y;
      const frente = dx * hx + dy * hy;
      const lateral = Math.abs(dx * hy - dy * hx);
      const radio = Math.max(o.w, o.h) / 2;
      if (frente > 0 && frente - radio < this.o.distanciaParo && lateral < radio + MEDIO_ANCHO) return true;
    }
    return false;
  }

  private sensar() {
    for (const o of this.mundo.values()) {
      if (!this.conocidos.has(o.id) && distancia(o, this.st) <= this.o.alcanceSensor) {
        this.conocidos.add(o.id);
        this.oyentes.alMensaje({ tipo: 'objeto', objeto: o });
      }
    }
    for (const id of [...this.conocidos]) {
      if (!this.mundo.has(id)) {
        this.conocidos.delete(id);
        this.oyentes.alMensaje({ tipo: 'objetoQuitado', id });
      }
    }
  }

  private evento(codigo: string) {
    this.oyentes.alMensaje({ tipo: 'evento', evento: { codigo, fecha: Date.now() } });
  }

  private cambiar(s: StatusRobot) {
    if (s.estado !== this.st.estado) this.tiempoEnEstado = 0;
    this.emitir(s);
  }

  private emitir(s: StatusRobot) {
    this.st = s;
    this.oyentes.alMensaje({ tipo: 'status', status: s });
  }
}

function envolver(a: number) {
  while (a > Math.PI) a -= 2 * Math.PI;
  while (a < -Math.PI) a += 2 * Math.PI;
  return a;
}
