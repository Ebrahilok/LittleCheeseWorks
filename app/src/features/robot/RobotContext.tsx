import { createContext, useCallback, useContext, useEffect, useMemo, useReducer, useRef } from 'react';
import type { ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import { RobotSimulado } from './RobotSimulado';
import { RobotWebSocket } from './RobotWebSocket';
import type { RobotService, OyentesRobot } from './RobotService';
import type { Punto } from './modelo';
import { robotInicial, robotReducer } from './robotReducer';
import type { RobotState } from './robotReducer';

const CLAVE_IP = 'robot_ip';
export const IP_POR_DEFECTO = '192.168.4.1';

interface RobotContextValue extends RobotState {
  conectarSimulado: () => Promise<void>;
  conectarReal: (ip: string) => Promise<void>;
  desconectar: () => void;
  calibrar: () => void;
  irA: (p: Punto) => void;
  retirarCarga: () => void;
  paro: () => void;
  reiniciar: () => void;
  colocarObjeto: (p: Punto) => void;
  quitarUltimoObjeto: () => void;
  perderUbicacion: () => void;
  marcarAlertasLeidas: () => void;
  borrarAlertas: () => void;
  ultimaIp: () => Promise<string>;
}

const RobotContext = createContext<RobotContextValue | undefined>(undefined);

export function RobotProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(robotReducer, robotInicial);
  const servicio = useRef<RobotService | null>(null);
  const { cuarto } = useCuarto();

  // El simulador usa las medidas actuales del cuarto
  useEffect(() => {
    if (servicio.current instanceof RobotSimulado) servicio.current.cuarto = cuarto;
  }, [cuarto]);

  useEffect(() => () => servicio.current?.cerrar(), []);

  const oyentes: OyentesRobot = useMemo(() => ({
    alMensaje: (mensaje) => dispatch({ tipo: 'MENSAJE', mensaje }),
    alCambiarConexion: (conectado) => dispatch({ tipo: 'CONEXION', conectado }),
  }), []);

  const iniciar = useCallback(async (nuevo: RobotService, simulado: boolean) => {
    servicio.current?.cerrar();
    servicio.current = nuevo;
    dispatch({ tipo: 'INICIAR', simulado });
    try {
      await nuevo.conectar();
    } catch (e) {
      nuevo.cerrar();
      servicio.current = null;
      dispatch({ tipo: 'DESCONECTAR' });
      throw e;
    }
  }, []);

  const enviar = (c: Parameters<RobotService['enviar']>[0]) => servicio.current?.enviar(c);
  const sim = () => (servicio.current instanceof RobotSimulado ? servicio.current : null);

  const value: RobotContextValue = {
    ...state,
    conectarSimulado: () => iniciar(new RobotSimulado(oyentes, cuarto), true),
    conectarReal: async (ip) => {
      await AsyncStorage.setItem(CLAVE_IP, ip).catch(() => {});
      await iniciar(new RobotWebSocket(`ws://${ip}:81`, oyentes), false);
    },
    desconectar: () => {
      servicio.current?.cerrar();
      servicio.current = null;
      dispatch({ tipo: 'DESCONECTAR' });
    },
    calibrar: () => enviar({ cmd: 'calibrate' }),
    irA: (p) => {
      // Nunca se manda un destino que no sea número (el robot real no sabría qué hacer)
      if (Number.isFinite(p.x) && Number.isFinite(p.y)) {
        enviar({ cmd: 'goto', x: Number(p.x.toFixed(2)), y: Number(p.y.toFixed(2)) });
      }
    },
    retirarCarga: () => enviar({ cmd: 'unload' }),
    paro: () => enviar({ cmd: 'stop' }),
    reiniciar: () => enviar({ cmd: 'reset' }),
    colocarObjeto: (p) => sim()?.colocarObjeto(p.x, p.y),
    quitarUltimoObjeto: () => sim()?.quitarUltimoObjeto(),
    perderUbicacion: () => sim()?.perderUbicacion(),
    marcarAlertasLeidas: () => dispatch({ tipo: 'ALERTAS_LEIDAS' }),
    borrarAlertas: () => dispatch({ tipo: 'BORRAR_ALERTAS' }),
    ultimaIp: async () => (await AsyncStorage.getItem(CLAVE_IP).catch(() => null)) ?? IP_POR_DEFECTO,
  };

  return <RobotContext.Provider value={value}>{children}</RobotContext.Provider>;
}

export function useRobot(): RobotContextValue {
  const c = useContext(RobotContext);
  if (!c) throw new Error('useRobot se tiene que usar dentro de un RobotProvider.');
  return c;
}
