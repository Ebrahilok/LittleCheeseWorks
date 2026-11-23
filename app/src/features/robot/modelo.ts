// Modelo del robot y protocolo JSON (igual al de la versión Flutter y al firmware).
// Coordenadas en metros respecto a la base: +x a la derecha, +y hacia abajo.

export interface Punto {
  x: number;
  y: number;
}

export const distancia = (a: Punto, b: Punto) => Math.hypot(a.x - b.x, a.y - b.y);

// ---------- Cuarto ----------
/** Cuarto visto desde arriba. La base del robot es el origen (0, 0). */
export interface Cuarto {
  ancho: number;
  largo: number;
  /** Distancia de la base a la pared izquierda. */
  baseX: number;
  /** Distancia de la base a la pared superior. */
  baseY: number;
}

export const CUARTO_ESTANDAR: Cuarto = { ancho: 6, largo: 4, baseX: 0.5, baseY: 0.5 };
export const CUARTO_CLASE: Cuarto = { ancho: 2, largo: 2, baseX: 0.25, baseY: 0.25 };
export const LADO_MIN = 1;
export const LADO_MAX = 20;

export const limites = (c: Cuarto) => ({
  minX: -c.baseX,
  minY: -c.baseY,
  maxX: c.ancho - c.baseX,
  maxY: c.largo - c.baseY,
});

export function cuartoValido(c: Cuarto): boolean {
  return (
    c.ancho >= LADO_MIN && c.largo >= LADO_MIN && c.ancho <= LADO_MAX && c.largo <= LADO_MAX &&
    c.baseX >= 0 && c.baseY >= 0 && c.baseX <= c.ancho && c.baseY <= c.largo
  );
}

export function dentroDelCuarto(c: Cuarto, p: Punto): boolean {
  const l = limites(c);
  return p.x >= l.minX && p.x <= l.maxX && p.y >= l.minY && p.y <= l.maxY;
}

export function ajustarAlCuarto(c: Cuarto, p: Punto): Punto {
  const l = limites(c);
  return {
    x: Math.min(Math.max(p.x, l.minX), l.maxX),
    y: Math.min(Math.max(p.y, l.minY), l.maxY),
  };
}

// La API guarda los puntos medidos desde la esquina superior izquierda (0..ancho),
// la app y el robot los usan medidos desde la base.
export const aCoordenadasPared = (c: Cuarto, p: Punto): Punto => ({ x: p.x + c.baseX, y: p.y + c.baseY });
export const aCoordenadasBase = (c: Cuarto, p: Punto): Punto => ({ x: p.x - c.baseX, y: p.y - c.baseY });

// ---------- Estado del robot ----------
export type EstadoRobot =
  | 'ESPERANDO_CARGA' | 'LISTO' | 'EN_RUTA' | 'OBSTACULO'
  | 'ENTREGANDO' | 'REGRESANDO' | 'ERROR' | 'PARO';

export const ETIQUETA_ESTADO: Record<EstadoRobot, string> = {
  ESPERANDO_CARGA: 'Esperando carga en la base',
  LISTO: 'Listo',
  EN_RUTA: 'En ruta',
  OBSTACULO: 'Obstáculo detectado',
  ENTREGANDO: 'Esperando retiro de la carga',
  REGRESANDO: 'Regresando a la base',
  ERROR: 'Error',
  PARO: 'Paro de emergencia',
};

const ESTADOS = Object.keys(ETIQUETA_ESTADO) as EstadoRobot[];
export const esFalla = (e: EstadoRobot) => e === 'ERROR' || e === 'PARO';
export const enMovimiento = (e: EstadoRobot) => e === 'EN_RUTA' || e === 'REGRESANDO';

export interface StatusRobot {
  estado: EstadoRobot;
  x: number;
  y: number;
  /** Orientación en radianes (0 = +x). */
  rumbo: number;
  conCarga: boolean;
  calibrado: boolean;
  destino: Punto | null;
  bateria: number;
  obstaculo: boolean;
}

export const STATUS_INICIAL: StatusRobot = {
  estado: 'ESPERANDO_CARGA', x: 0, y: 0, rumbo: 0, conCarga: false,
  calibrado: false, destino: null, bateria: 100, obstaculo: false,
};

export interface ObjetoDetectado {
  id: number;
  x: number;
  y: number;
  w: number;
  h: number;
}

// ---------- Eventos ----------
export const EVENTOS = {
  ubicacionPerdida: 'LOCALIZATION_LOST',
  bateriaBaja: 'LOW_BATTERY',
  obstaculoProlongado: 'OBSTACLE_TIMEOUT',
  conexionPerdida: 'CONNECTION_LOST',
  objetoDetectado: 'OBJECT_DETECTED',
} as const;

export interface EventoRobot {
  codigo: string;
  detalle?: string;
  fecha: number;
}

export function describirEvento(e: EventoRobot): string {
  switch (e.codigo) {
    case EVENTOS.ubicacionPerdida: return 'El robot perdió su ubicación';
    case EVENTOS.bateriaBaja: return 'Batería baja';
    case EVENTOS.obstaculoProlongado: return 'Obstáculo prolongado (más de 30 s)';
    case EVENTOS.conexionPerdida: return 'Se perdió la conexión con el robot';
    case EVENTOS.objetoDetectado: return `Objeto detectado${e.detalle ? ` en ${e.detalle}` : ''}`;
    default: return `Falla: ${e.codigo}`;
  }
}

// ---------- Comandos App -> Robot ----------
export type Comando =
  | { cmd: 'calibrate' }
  | { cmd: 'goto'; x: number; y: number }
  | { cmd: 'unload' }
  | { cmd: 'stop' }
  | { cmd: 'reset' };

// ---------- Mensajes Robot -> App ----------
export type MensajeRobot =
  | { tipo: 'status'; status: StatusRobot }
  | { tipo: 'evento'; evento: EventoRobot }
  | { tipo: 'objeto'; objeto: ObjetoDetectado }
  | { tipo: 'objetoQuitado'; id: number };

const num = (v: unknown, def = 0) => (typeof v === 'number' && Number.isFinite(v) ? v : def);

/** Regresa null si el texto no es JSON válido o no es un mensaje conocido. */
export function leerMensaje(texto: string): MensajeRobot | null {
  let j: any;
  try {
    j = JSON.parse(texto);
  } catch {
    return null;
  }
  if (!j || typeof j !== 'object' || Array.isArray(j)) return null;

  if ('state' in j) {
    const t = j.target;
    return {
      tipo: 'status',
      status: {
        estado: ESTADOS.includes(j.state) ? j.state : 'ERROR',
        x: num(j.x),
        y: num(j.y),
        rumbo: num(j.heading),
        conCarga: j.load === true,
        calibrado: j.calibrated === true,
        destino: t && typeof t === 'object' ? { x: num(t.x), y: num(t.y) } : null,
        bateria: Math.round(num(j.battery)),
        obstaculo: j.obstacle === true,
      },
    };
  }
  switch (j.event) {
    case 'error':
      return typeof j.code === 'string'
        ? { tipo: 'evento', evento: { codigo: j.code, fecha: Date.now() } }
        : null;
    case 'object':
      if (typeof j.id !== 'number') return null;
      return {
        tipo: 'objeto',
        objeto: { id: j.id, x: num(j.x), y: num(j.y), w: num(j.w, 0.3), h: num(j.h, 0.3) },
      };
    case 'object_gone':
      return typeof j.id === 'number' ? { tipo: 'objetoQuitado', id: j.id } : null;
    default:
      return null;
  }
}
