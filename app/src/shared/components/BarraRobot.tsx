import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useRobot } from '@/features/robot/RobotContext';
import { Colores } from '@/constants/Theme';

/** Botón rojo de paro (RF-10). Se muestra en el encabezado mientras hay robot. */
export function BotonParo() {
  const { conectado, paro } = useRobot();
  if (!conectado) return null;
  return (
    <Pressable onPress={paro} accessibilityLabel="Paro de emergencia" style={({ pressed }) => [e.paro, pressed && { opacity: 0.8 }]}>
      <Ionicons name="stop-circle" size={18} color="#fff" />
      <Text style={e.textoParo}>PARO</Text>
    </Pressable>
  );
}

/** Banda roja cuando se cayó la conexión con el robot real (RNF-06). */
export function BandaReconexion() {
  const { reconectando } = useRobot();
  if (!reconectando) return null;
  return (
    <View style={e.banda}>
      <Ionicons name="cloud-offline" size={18} color={Colores.peligro} />
      <Text style={e.textoBanda}>Conexión perdida con el robot. Reconectando…</Text>
    </View>
  );
}

const e = StyleSheet.create({
  paro: {
    flexDirection: 'row', alignItems: 'center', gap: 4, backgroundColor: Colores.peligro,
    paddingHorizontal: 12, paddingVertical: 8, borderRadius: 20, marginRight: 12,
  },
  textoParo: { color: '#fff', fontWeight: '800', letterSpacing: 0.5 },
  banda: {
    flexDirection: 'row', gap: 8, alignItems: 'center', padding: 10,
    backgroundColor: Colores.peligroSuave, borderBottomWidth: 1, borderColor: '#F5C2BE',
  },
  textoBanda: { color: Colores.peligro, fontWeight: '600', flex: 1 },
});
