import { createContext, useContext, useEffect, useMemo, useReducer } from 'react';
import type { ReactNode } from 'react';
import { registrarAlExpirarSesion } from '@/shared/api/axiosInstance';
import { authService } from './authService';
import { authReducer, estadoInicial } from './authReducer';
import type { AuthState } from './authReducer';
import type { LoginDto, RegistroDto } from './types';

interface AuthContextValue extends AuthState {
  signIn: (dto: LoginDto) => Promise<void>;
  signUp: (dto: RegistroDto) => Promise<void>;
  entrarDemo: () => Promise<void>;
  logOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(authReducer, estadoInicial);

  // Al abrir la app se busca una sesión guardada
  useEffect(() => {
    let activo = true;
    authService
      .restaurarSesion()
      .catch(() => null)
      .then((sesion) => {
        if (activo) dispatch(sesion ? { tipo: 'SESION_RESTAURADA', sesion } : { tipo: 'SIN_SESION' });
      });
    return () => {
      activo = false;
    };
  }, []);

  // Si el servidor responde 401 (token vencido) la sesión se cierra sola
  useEffect(() => {
    registrarAlExpirarSesion(() => {
      void authService.signOut();
      dispatch({ tipo: 'SIGN_OUT' });
    });
    return () => registrarAlExpirarSesion(null);
  }, []);

  const value = useMemo<AuthContextValue>(() => ({
    ...state,
    signIn: async (dto) => dispatch({ tipo: 'SIGN_IN', sesion: await authService.signIn(dto) }),
    signUp: async (dto) => dispatch({ tipo: 'SIGN_IN', sesion: await authService.signUp(dto) }),
    entrarDemo: async () => dispatch({ tipo: 'SIGN_IN', sesion: await authService.entrarDemo() }),
    logOut: async () => {
      await authService.signOut();
      dispatch({ tipo: 'SIGN_OUT' });
    },
  }), [state]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const c = useContext(AuthContext);
  if (!c) throw new Error('useAuth se tiene que usar dentro de un AuthProvider.');
  return c;
}
