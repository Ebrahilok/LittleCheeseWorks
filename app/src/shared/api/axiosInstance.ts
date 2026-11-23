import axios, { AxiosError } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Dirección del backend. En el celular no existe "localhost": hay que poner la
// IP de la computadora donde corre la API, por ejemplo http://192.168.1.70:5150.
// En el emulador de Android la computadora es 10.0.2.2.
const CLAVE_SERVIDOR = 'servidor_url';
export const SERVIDOR_POR_DEFECTO = 'http://10.0.2.2:5150';

let servidor = SERVIDOR_POR_DEFECTO;
let token: string | null = null;
let alExpirar: (() => void) | null = null;

export async function cargarServidor(): Promise<string> {
  servidor = (await AsyncStorage.getItem(CLAVE_SERVIDOR).catch(() => null)) ?? SERVIDOR_POR_DEFECTO;
  return servidor;
}

export async function guardarServidor(url: string) {
  servidor = url.trim().replace(/\/+$/, '');
  if (!/^https?:\/\//.test(servidor)) servidor = `http://${servidor}`;
  await AsyncStorage.setItem(CLAVE_SERVIDOR, servidor).catch(() => {});
}

export const servidorActual = () => servidor;
export const ponerToken = (t: string | null) => {
  token = t;
};
export const registrarAlExpirarSesion = (fn: (() => void) | null) => {
  alExpirar = fn;
};

export const api = axios.create({ timeout: 8000 });

// Cada petición sale con la dirección del servidor y el token de la sesión
api.interceptors.request.use((config) => {
  config.baseURL = `${servidor}/api`;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Un 401 con sesión abierta significa que el token venció: se cierra la sesión
api.interceptors.response.use(undefined, (error: AxiosError) => {
  if (error.response?.status === 401 && token && alExpirar) alExpirar();
  return Promise.reject(error);
});

/** Respuesta estándar de la API (ApiResponse en el backend). */
export interface ApiResponse<T> {
  exito: boolean;
  mensaje: string;
  datos: T;
  errores: string[] | null;
}

/** Convierte cualquier error en un texto que se pueda mostrar en pantalla. */
export function mensajeDeError(e: unknown): string {
  if (axios.isAxiosError(e)) {
    const r = e.response?.data as Partial<ApiResponse<unknown>> | undefined;
    if (r?.errores?.length) return r.errores.join('\n');
    if (r?.mensaje) return r.mensaje;
    if (!e.response) return `No se pudo conectar con el servidor (${servidor}). Revisa que la API esté corriendo y que el celular esté en la misma red WiFi.`;
    return `El servidor respondió con error ${e.response.status}.`;
  }
  return e instanceof Error ? e.message : 'Ocurrió un error inesperado.';
}
