import { FlatList, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useRobot } from '@/features/robot/RobotContext';
import { describirEvento, EVENTOS } from '@/features/robot/modelo';
import { BotonAccion } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

type Icono = keyof typeof Ionicons.glyphMap;

// Las fallas van en rojo; las detecciones de objetos solo informan
function apariencia(codigo: string): [Icono, string] {
  switch (codigo) {
    case EVENTOS.objetoDetectado: return ['scan', '#546E7A'];
    case EVENTOS.bateriaBaja: return ['battery-dead', Colores.aviso];
    case EVENTOS.conexionPerdida: return ['cloud-offline', Colores.peligro];
    case EVENTOS.obstaculoProlongado: return ['hand-left', Colores.peligro];
    case EVENTOS.ubicacionPerdida: return ['navigate-circle', Colores.peligro];
    default: return ['warning', Colores.peligro];
  }
}

const hora = (t: number) => new Date(t).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', second: '2-digit' });

export default function Alertas() {
  const { alertas, borrarAlertas } = useRobot();

  if (alertas.length === 0) {
    return (
      <View style={e.vacio}>
        <Ionicons name="notifications-off-outline" size={48} color={Colores.borde} />
        <Text style={e.textoVacio}>Sin alertas.</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={alertas}
      keyExtractor={(_, i) => String(i)}
      ListHeaderComponent={
        <BotonAccion titulo="Borrar historial" icono="trash-outline" variante="texto" onPress={borrarAlertas}
          estilo={{ alignSelf: 'flex-end' }} />
      }
      ItemSeparatorComponent={() => <View style={e.separador} />}
      renderItem={({ item }) => {
        const [icono, color] = apariencia(item.codigo);
        return (
          <View style={e.fila}>
            <Ionicons name={icono} size={24} color={color} />
            <View style={{ flex: 1 }}>
              <Text style={e.titulo}>{describirEvento(item)}</Text>
              <Text style={e.hora}>{hora(item.fecha)}</Text>
            </View>
          </View>
        );
      }}
    />
  );
}

const e = StyleSheet.create({
  vacio: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 8 },
  textoVacio: { color: Colores.textoSuave, fontSize: 16 },
  fila: { flexDirection: 'row', gap: 14, alignItems: 'center', paddingHorizontal: 16, paddingVertical: 12, backgroundColor: '#fff' },
  titulo: { fontSize: 15, color: Colores.texto },
  hora: { fontSize: 13, color: Colores.textoSuave, marginTop: 2 },
  separador: { height: 1, backgroundColor: '#EEE9E1' },
});
