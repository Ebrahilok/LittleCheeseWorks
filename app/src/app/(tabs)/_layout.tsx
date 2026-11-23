import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useRobot } from '@/features/robot/RobotContext';
import { BotonParo } from '@/shared/components/BarraRobot';
import { Colores } from '@/constants/Theme';

type NombreIcono = keyof typeof Ionicons.glyphMap;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const icono = (nombre: NombreIcono) => ({ color, size }: { color: any; size: number }) =>
  <Ionicons name={nombre} size={size} color={color} />;

export default function TabsLayout() {
  const { sinLeer, marcarAlertasLeidas } = useRobot();
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Colores.primario,
        headerStyle: { backgroundColor: '#fff' },
        headerTitleStyle: { fontWeight: '700' },
        headerRight: () => <BotonParo />,
        sceneStyle: { backgroundColor: Colores.fondo },
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Mapa', tabBarIcon: icono('map') }} />
      <Tabs.Screen name="puntos" options={{ title: 'Puntos', headerShown: false, tabBarIcon: icono('bookmark') }} />
      <Tabs.Screen name="robot" options={{ title: 'Robot', tabBarIcon: icono('hardware-chip') }} />
      <Tabs.Screen
        name="alertas"
        options={{ title: 'Alertas', tabBarIcon: icono('notifications'), tabBarBadge: sinLeer > 0 ? sinLeer : undefined }}
        listeners={{ focus: marcarAlertasLeidas }}
      />
      <Tabs.Screen name="perfil" options={{ title: 'Perfil', tabBarIcon: icono('person-circle') }} />
    </Tabs>
  );
}
