import { Platform } from 'react-native';
import * as SecureStoreNativo from 'expo-secure-store';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api, cargarServidor, ponerToken } from '@/shared/api/axiosInstance';

// En Android/iOS el token va cifrado; en la versión web (solo para pruebas) no existe
// secure-store y se usa el almacenamiento del navegador.
const SecureStore = Platform.OS === 'web'
  ? {
      setItemAsync: (k: string, v: string) => AsyncStorage.setItem(k, v),
      getItemAsync: (k: string) => AsyncStorage.getItem(k),
      deleteItemAsync: (k: string) => AsyncStorage.removeItem(k),
    }
  : SecureStoreNativo;
import type { ApiResponse } from '@/shared/api/axiosInstance';
import type { LoginDto, RegistroDto, Sesion, Usuario } from './types';

// La sesión se guarda cifrada en el teléfono con expo-secure-store
const CLAVE_SESION = 'sesion_v1';

interface LoginRespuesta {
  tokenAcceso: string;
  expira: string;
  usuario: Usuario;
}

async function guardar(s: Sesion) {
  ponerToken(s.token);
  await SecureStore.setItemAsync(CLAVE_SESION, JSON.stringify(s));
}

export const authService = {
  async signIn(dto: LoginDto): Promise<Sesion> {
    const { data } = await api.post<ApiResponse<LoginRespuesta>>('/auth/login', {
      email: dto.email.trim(),
      password: dto.password,
    });
    const sesion: Sesion = {
      modo: 'api',
      usuario: data.datos.usuario,
      token: data.datos.tokenAcceso,
      expira: data.datos.expira,
    };
    await guardar(sesion);
    return sesion;
  },

  /** Crea la cuenta y enseguida inicia sesión con ella. */
  async signUp(dto: RegistroDto): Promise<Sesion> {
    await api.post<ApiResponse<Usuario>>('/auth/registro', {
      nombre: dto.nombre.trim(),
      email: dto.email.trim(),
      password: dto.password,
    });
    return authService.signIn(dto);
  },

  async entrarDemo(): Promise<Sesion> {
    const sesion: Sesion = {
      modo: 'demo',
      usuario: { id: 0, nombre: 'Modo demo', email: 'sin servidor', rol: 'Operador' },
      token: null,
      expira: null,
    };
    await guardar(sesion);
    return sesion;
  },

  /** Al abrir la app: regresa la sesión guardada si todavía sirve. */
  async restaurarSesion(): Promise<Sesion | null> {
    await cargarServidor();
    const texto = await SecureStore.getItemAsync(CLAVE_SESION);
    if (!texto) return null;
    const s = JSON.parse(texto) as Sesion;
    if (s.modo === 'api' && (!s.expira || new Date(s.expira).getTime() <= Date.now())) {
      await authService.signOut();
      return null;
    }
    ponerToken(s.token);
    return s;
  },

  async signOut() {
    ponerToken(null);
    await SecureStore.deleteItemAsync(CLAVE_SESION);
  },
};
