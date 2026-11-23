import { distancia, EVENTOS, STATUS_INICIAL } from './modelo';
import type { EventoRobot, MensajeRobot, ObjetoDetectado, Punto, StatusRobot } from './modelo';

export interface RobotState {
  conectado: boolean;
  /** Se cayó la conexión con el robot real y la app está reintentando. */
  reconectando: boolean;
  simulado: boolean;
  status: StatusRobot;
  objetos: ObjetoDetectado[];
  alertas: EventoRobot[];
  sinLeer: number;
  /** Recorrido desde que salió de la base, para dibujarlo en el mapa. */
  recorrido: Punto[];
}

export const robotInicial: RobotState = {
  conectado: false, reconectando: false, simulado: false, status: STATUS_INICIAL,
  objetos: [], alertas: [], sinLeer: 0, recorrido: [],
};

export type AccionRobot =
  | { tipo: 'INICIAR'; simulado: boolean }
  | { tipo: 'CONEXION'; conectado: boolean }
  | { tipo: 'MENSAJE'; mensaje: MensajeRobot }
  | { tipo: 'ALERTAS_LEIDAS' }
  | { tipo: 'BORRAR_ALERTAS' }
  | { tipo: 'DESCONECTAR' };

const PASO_RECORRIDO = 0.03;
const MAX_RECORRIDO = 600;

function agregarAlerta(s: RobotState, e: EventoRobot): RobotState {
  return { ...s, alertas: [e, ...s.alertas].slice(0, 200), sinLeer: s.sinLeer + 1 };
}

export function robotReducer(s: RobotState, a: AccionRobot): RobotState {
  switch (a.tipo) {
    case 'INICIAR':
      // Sesión limpia; las alertas anteriores se conservan
      return { ...robotInicial, simulado: a.simulado, alertas: s.alertas, sinLeer: s.sinLeer };
    case 'CONEXION':
      // Solo el robot real se reconecta solo; el simulado nunca se cae
      return { ...s, conectado: a.conectado, reconectando: !a.conectado && !s.simulado };
    case 'ALERTAS_LEIDAS':
      return { ...s, sinLeer: 0 };
    case 'BORRAR_ALERTAS':
      return { ...s, alertas: [], sinLeer: 0 };
    case 'DESCONECTAR':
      return { ...robotInicial, alertas: s.alertas, sinLeer: s.sinLeer };
    case 'MENSAJE': {
      const m = a.mensaje;
      switch (m.tipo) {
        case 'status': {
          const st = m.status;
          let recorrido = s.recorrido;
          if (!st.calibrado || st.estado === 'ESPERANDO_CARGA') {
            recorrido = []; // de vuelta en la base: empieza otro recorrido
          } else if (recorrido.length === 0 || distancia(recorrido[recorrido.length - 1], st) >= PASO_RECORRIDO) {
            recorrido = [...recorrido, { x: st.x, y: st.y }].slice(-MAX_RECORRIDO);
          }
          return { ...s, status: st, recorrido };
        }
        case 'evento':
          return agregarAlerta(s, m.evento);
        case 'objeto': {
          const o = m.objeto;
          const con = { ...s, objetos: [...s.objetos.filter((x) => x.id !== o.id), o] };
          return agregarAlerta(con, {
            codigo: EVENTOS.objetoDetectado,
            detalle: `(${o.x.toFixed(1)}, ${o.y.toFixed(1)}) m`,
            fecha: Date.now(),
          });
        }
        case 'objetoQuitado':
          return { ...s, objetos: s.objetos.filter((x) => x.id !== m.id) };
      }
    }
  }
  return s;
}
