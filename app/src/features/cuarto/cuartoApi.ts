import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '@/shared/api/axiosInstance';
import type { ApiResponse } from '@/shared/api/axiosInstance';
import { aCoordenadasBase, aCoordenadasPared, CUARTO_ESTANDAR, dentroDelCuarto } from '@/features/robot/modelo';
import type { Cuarto, Punto } from '@/features/robot/modelo';

/** Punto guardado tal como lo usa la app: coordenadas medidas desde la base. */
export interface PuntoGuardado extends Punto {
  id: number;
  nombre: string;
  fechaCreacion: string;
}

export interface CuartoGuardado extends Cuarto {
  id: number;
  nombre: string;
}

/** Contrato común: el backend real o el almacenamiento local del modo demo. */
export interface CuartoRepo {
  obtenerCuarto(): Promise<CuartoGuardado>;
  editarCuarto(c: CuartoGuardado): Promise<CuartoGuardado>;
  listarPuntos(c: CuartoGuardado): Promise<PuntoGuardado[]>;
  obtenerPunto(c: CuartoGuardado, id: number): Promise<PuntoGuardado>;
  crearPunto(c: CuartoGuardado, nombre: string, p: Punto): Promise<PuntoGuardado>;
  editarPunto(c: CuartoGuardado, id: number, nombre: string, p: Punto): Promise<PuntoGuardado>;
  eliminarPunto(id: number): Promise<void>;
}

// ---------------- Backend (ASP.NET) ----------------
interface CuartoDto { id: number; nombre: string; anchoM: number; largoM: number; baseX: number; baseY: number }
interface PuntoDto { id: number; cuartoId: number; nombre: string; x: number; y: number; fechaCreacion: string }

const deDto = (d: CuartoDto): CuartoGuardado => ({
  id: d.id, nombre: d.nombre, ancho: d.anchoM, largo: d.largoM, baseX: d.baseX, baseY: d.baseY,
});
const aDto = (c: CuartoGuardado) => ({
  nombre: c.nombre, anchoM: c.ancho, largoM: c.largo, baseX: c.baseX, baseY: c.baseY,
});
// La API mide los puntos desde la esquina del cuarto; la app desde la base
const puntoDeDto = (c: Cuarto, d: PuntoDto): PuntoGuardado => ({
  id: d.id, nombre: d.nombre, fechaCreacion: d.fechaCreacion, ...aCoordenadasBase(c, d),
});
const redondear = (p: Punto) => ({ x: Math.round(p.x * 100) / 100, y: Math.round(p.y * 100) / 100 });

export const cuartoApi: CuartoRepo = {
  async obtenerCuarto() {
    const { data } = await api.get<ApiResponse<CuartoDto[]>>('/cuartos');
    if (data.datos.length > 0) return deDto(data.datos[0]);
    // Primera vez: se crea un cuarto con las medidas estándar
    const nuevo = await api.post<ApiResponse<CuartoDto>>('/cuartos', aDto({ id: 0, nombre: 'Mi cuarto', ...CUARTO_ESTANDAR }));
    return deDto(nuevo.data.datos);
  },
  async editarCuarto(c) {
    const { data } = await api.put<ApiResponse<CuartoDto>>(`/cuartos/${c.id}`, aDto(c));
    return deDto(data.datos);
  },
  async listarPuntos(c) {
    const { data } = await api.get<ApiResponse<PuntoDto[]>>('/puntos', { params: { cuartoId: c.id } });
    return data.datos.map((d) => puntoDeDto(c, d));
  },
  async obtenerPunto(c, id) {
    const { data } = await api.get<ApiResponse<PuntoDto>>(`/puntos/${id}`);
    return puntoDeDto(c, data.datos);
  },
  async crearPunto(c, nombre, p) {
    const { data } = await api.post<ApiResponse<PuntoDto>>('/puntos', {
      cuartoId: c.id, nombre, ...redondear(aCoordenadasPared(c, p)),
    });
    return puntoDeDto(c, data.datos);
  },
  async editarPunto(c, id, nombre, p) {
    const { data } = await api.put<ApiResponse<PuntoDto>>(`/puntos/${id}`, {
      cuartoId: c.id, nombre, ...redondear(aCoordenadasPared(c, p)),
    });
    return puntoDeDto(c, data.datos);
  },
  async eliminarPunto(id) {
    await api.delete(`/puntos/${id}`);
  },
};

// ---------------- Modo demo (sin servidor) ----------------
const K_CUARTO = 'demo_cuarto';
const K_PUNTOS = 'demo_puntos';

async function leer<T>(clave: string, def: T): Promise<T> {
  const t = await AsyncStorage.getItem(clave).catch(() => null);
  return t ? (JSON.parse(t) as T) : def;
}
const escribir = (clave: string, v: unknown) => AsyncStorage.setItem(clave, JSON.stringify(v));

// Mismas reglas que el backend, para que el modo demo se comporte igual
async function validar(c: Cuarto, nombre: string, p: Punto, idActual?: number) {
  if (!nombre.trim()) throw new Error('El nombre del punto es obligatorio.');
  if (!dentroDelCuarto(c, p)) throw new Error(`El punto queda fuera del cuarto (${c.ancho} x ${c.largo} m).`);
  const puntos = await leer<PuntoGuardado[]>(K_PUNTOS, []);
  if (puntos.some((x) => x.id !== idActual && x.nombre.toLowerCase() === nombre.trim().toLowerCase())) {
    throw new Error(`Ya hay un punto llamado "${nombre.trim()}" en este cuarto.`);
  }
  return puntos;
}

export const cuartoLocal: CuartoRepo = {
  obtenerCuarto: () => leer<CuartoGuardado>(K_CUARTO, { id: 1, nombre: 'Mi cuarto', ...CUARTO_ESTANDAR }),
  async editarCuarto(c) {
    const fuera = (await leer<PuntoGuardado[]>(K_PUNTOS, [])).filter((p) => !dentroDelCuarto(c, p));
    if (fuera.length) {
      throw new Error(`Con esas medidas quedarían fuera del cuarto los puntos: ${fuera.map((p) => p.nombre).join(', ')}.`);
    }
    await escribir(K_CUARTO, c);
    return c;
  },
  listarPuntos: async () => (await leer<PuntoGuardado[]>(K_PUNTOS, [])).sort((a, b) => a.nombre.localeCompare(b.nombre)),
  async obtenerPunto(_c, id) {
    const p = (await leer<PuntoGuardado[]>(K_PUNTOS, [])).find((x) => x.id === id);
    if (!p) throw new Error('El punto no existe.');
    return p;
  },
  async crearPunto(c, nombre, p) {
    const puntos = await validar(c, nombre, p);
    const nuevo: PuntoGuardado = {
      id: Math.max(0, ...puntos.map((x) => x.id)) + 1, nombre: nombre.trim(),
      fechaCreacion: new Date().toISOString(), ...redondear(p),
    };
    await escribir(K_PUNTOS, [...puntos, nuevo]);
    return nuevo;
  },
  async editarPunto(c, id, nombre, p) {
    const puntos = await validar(c, nombre, p, id);
    const actual = puntos.find((x) => x.id === id);
    if (!actual) throw new Error('El punto no existe.');
    const editado = { ...actual, nombre: nombre.trim(), ...redondear(p) };
    await escribir(K_PUNTOS, puntos.map((x) => (x.id === id ? editado : x)));
    return editado;
  },
  async eliminarPunto(id) {
    await escribir(K_PUNTOS, (await leer<PuntoGuardado[]>(K_PUNTOS, [])).filter((x) => x.id !== id));
  },
};
