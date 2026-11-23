import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { AuthProvider, useAuth } from '@/features/auth/AuthContext';
import { CuartoProvider } from '@/features/cuarto/CuartoContext';
import { RobotProvider } from '@/features/robot/RobotContext';

SplashScreen.preventAutoHideAsync();

function Navegacion() {
  const { estado } = useAuth();

  useEffect(() => {
    if (estado !== 'checking') SplashScreen.hideAsync();
  }, [estado]);

  if (estado === 'checking') return null;

  return (
    <Stack screenOptions={{ headerShown: false }}>
      {/* Decide a dónde ir según la sesión */}
      <Stack.Screen name="index" />
      {/* Pestañas: solo con sesión */}
      <Stack.Protected guard={estado === 'authenticated'}>
        <Stack.Screen name="(tabs)" />
      </Stack.Protected>
      {/* Login y registro: solo sin sesión */}
      <Stack.Protected guard={estado === 'not-authenticated'}>
        <Stack.Screen name="(auth)" />
      </Stack.Protected>
    </Stack>
  );
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <CuartoProvider>
        <RobotProvider>
          <StatusBar style="dark" />
          <Navegacion />
        </RobotProvider>
      </CuartoProvider>
    </AuthProvider>
  );
}
