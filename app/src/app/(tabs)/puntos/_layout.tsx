import { Stack } from 'expo-router';
import { BotonParo } from '@/shared/components/BarraRobot';
import { Colores } from '@/constants/Theme';

export default function PuntosLayout() {
  return (
    <Stack screenOptions={{
      headerTitleStyle: { fontWeight: '700' },
      headerRight: () => <BotonParo />,
      contentStyle: { backgroundColor: Colores.fondo },
    }}>
      <Stack.Screen name="index" options={{ title: 'Puntos guardados' }} />
      <Stack.Screen name="[id]" options={{ title: 'Detalle del punto' }} />
      <Stack.Screen name="formulario" options={{ title: 'Punto' }} />
    </Stack>
  );
}
