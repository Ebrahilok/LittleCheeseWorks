import type { Sesion } from './types';

export type EstadoAuth = 'checking' | 'authenticated' | 'not-authenticated';

export interface AuthState {
  estado: EstadoAuth;
  sesion: Sesion | null;
}

export const estadoInicial: AuthState = { estado: 'checking', sesion: null };

export type AccionAuth =
  | { tipo: 'SESION_RESTAURADA'; sesion: Sesion }
  | { tipo: 'SIN_SESION' }
  | { tipo: 'SIGN_IN'; sesion: Sesion }
  | { tipo: 'SIGN_OUT' };

export function authReducer(state: AuthState, accion: AccionAuth): AuthState {
  switch (accion.tipo) {
    case 'SESION_RESTAURADA':
    case 'SIGN_IN':
      return { estado: 'authenticated', sesion: accion.sesion };
    case 'SIN_SESION':
    case 'SIGN_OUT':
      return { estado: 'not-authenticated', sesion: null };
    default:
      return state;
  }
}
