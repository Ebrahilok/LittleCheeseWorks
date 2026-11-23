import { Redirect } from 'expo-router';
import { useAuth } from '@/features/auth/AuthContext';

/** Entrada de la app: con sesión va al mapa, sin sesión al login. */
export default function Inicio() {
  const { estado } = useAuth();
  return <Redirect href={estado === 'authenticated' ? '/mapa' : '/login'} />;
}
