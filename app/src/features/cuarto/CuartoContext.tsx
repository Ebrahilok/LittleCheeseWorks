import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { useAuth } from '@/features/auth/AuthContext';
import { CUARTO_ESTANDAR, cuartoValido, LADO_MAX, LADO_MIN } from '@/features/robot/modelo';
import type { Punto } from '@/features/robot/modelo';
import { mensajeDeError } from '@/shared/api/axiosInstance';
import { cuartoApi, cuartoLocal } from './cuartoApi';
import type { CuartoGuardado, CuartoRepo, PuntoGuardado } from './cuartoApi';

interface CuartoContextValue {
  cuarto: CuartoGuardado;
  puntos: PuntoGuardado[];
  cargando: boolean;
  error: string | null;
  recargar: () => Promise<void>;
  guardarCuarto: (c: CuartoGuardado) => Promise<void>;
  obtenerPunto: (id: number) => Promise<PuntoGuardado>;
  crearPunto: (nombre: string, p: Punto) => Promise<PuntoGuardado>;
  editarPunto: (id: number, nombre: string, p: Punto) => Promise<PuntoGuardado>;
  eliminarPunto: (id: number) => Promise<void>;
}

const CuartoContext = createContext<CuartoContextValue | undefined>(undefined);
const CUARTO_VACIO: CuartoGuardado = { id: 0, nombre: 'Mi cuarto', ...CUARTO_ESTANDAR };

/** Los errores del backend llegan como texto legible a las pantallas. */
async function conMensaje<T>(f: () => Promise<T>): Promise<T> {
  try {
    return await f();
  } catch (e) {
    throw new Error(mensajeDeError(e));
  }
}

export function CuartoProvider({ children }: { children: ReactNode }) {
  const { sesion } = useAuth();
  const repo: CuartoRepo = sesion?.modo === 'api' ? cuartoApi : cuartoLocal;
  const [cuarto, setCuarto] = useState<CuartoGuardado>(CUARTO_VACIO);
  const [puntos, setPuntos] = useState<PuntoGuardado[]>([]);
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const recargar = useCallback(async () => {
    if (!sesion) return;
    setCargando(true);
    setError(null);
    try {
      const c = await repo.obtenerCuarto();
      setCuarto(c);
      setPuntos(await repo.listarPuntos(c));
    } catch (e) {
      setError(mensajeDeError(e));
    } finally {
      setCargando(false);
    }
  }, [sesion, repo]);

  useEffect(() => {
    if (sesion) void recargar();
    else {
      setCuarto(CUARTO_VACIO);
      setPuntos([]);
    }
  }, [sesion, recargar]);

  const value = useMemo<CuartoContextValue>(() => ({
    cuarto, puntos, cargando, error, recargar,
    guardarCuarto: (c) => conMensaje(async () => {
      if (!cuartoValido(c)) {
        throw new Error(`Cada lado debe medir entre ${LADO_MIN} y ${LADO_MAX} m y la base debe quedar dentro del cuarto.`);
      }
      setCuarto(await repo.editarCuarto(c));
    }),
    obtenerPunto: (id) => conMensaje(() => repo.obtenerPunto(cuarto, id)),
    crearPunto: (nombre, p) => conMensaje(async () => {
      const nuevo = await repo.crearPunto(cuarto, nombre, p);
      setPuntos((l) => [...l, nuevo].sort((a, b) => a.nombre.localeCompare(b.nombre)));
      return nuevo;
    }),
    editarPunto: (id, nombre, p) => conMensaje(async () => {
      const editado = await repo.editarPunto(cuarto, id, nombre, p);
      setPuntos((l) => l.map((x) => (x.id === id ? editado : x)));
      return editado;
    }),
    eliminarPunto: (id) => conMensaje(async () => {
      await repo.eliminarPunto(id);
      setPuntos((l) => l.filter((x) => x.id !== id));
    }),
  }), [cuarto, puntos, cargando, error, recargar, repo]);

  return <CuartoContext.Provider value={value}>{children}</CuartoContext.Provider>;
}

export function useCuarto(): CuartoContextValue {
  const c = useContext(CuartoContext);
  if (!c) throw new Error('useCuarto se tiene que usar dentro de un CuartoProvider.');
  return c;
}
