import { FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import { Aviso } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

export default function ListaPuntos() {
  const { puntos, cargando, error, recargar, cuarto } = useCuarto();

  return (
    <View style={{ flex: 1 }}>
      <FlatList
        data={puntos}
        keyExtractor={(p) => String(p.id)}
        contentContainerStyle={{ padding: 16, paddingBottom: 96 }}
        refreshControl={<RefreshControl refreshing={cargando} onRefresh={recargar} colors={[Colores.primario]} />}
        ListHeaderComponent={
          <>
            {error && <Aviso texto={error} />}
            <Text style={e.cuarto}>{cuarto.nombre} · {cuarto.ancho} × {cuarto.largo} m</Text>
          </>
        }
        ListEmptyComponent={!cargando ? (
          <View style={e.vacio}>
            <Ionicons name="bookmark-outline" size={44} color={Colores.borde} />
            <Text style={e.textoVacio}>Todavía no hay puntos guardados.</Text>
            <Text style={e.ayuda}>Pulsa + o elige un lugar en el mapa y pulsa Guardar.</Text>
          </View>
        ) : undefined}
        renderItem={({ item }) => (
          <Pressable style={({ pressed }) => [e.fila, pressed && { opacity: 0.7 }]}
            onPress={() => router.push(`/puntos/${item.id}`)}>
            <View style={e.icono}><Ionicons name="location" size={20} color={Colores.punto} /></View>
            <View style={{ flex: 1 }}>
              <Text style={e.nombre}>{item.nombre}</Text>
              <Text style={e.coords}>x {item.x.toFixed(2)} m · y {item.y.toFixed(2)} m desde la base</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={Colores.textoSuave} />
          </Pressable>
        )}
      />
      <Pressable accessibilityLabel="Agregar punto" style={({ pressed }) => [e.fab, pressed && { opacity: 0.85 }]}
        onPress={() => router.push('/puntos/formulario')}>
        <Ionicons name="add" size={30} color="#fff" />
      </Pressable>
    </View>
  );
}

const e = StyleSheet.create({
  cuarto: { color: Colores.textoSuave, marginBottom: 10 },
  fila: {
    flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: '#fff', padding: 14,
    borderRadius: 12, marginBottom: 8, borderWidth: 1, borderColor: '#ECE7DF',
  },
  icono: { width: 38, height: 38, borderRadius: 19, backgroundColor: '#F3E5F5', alignItems: 'center', justifyContent: 'center' },
  nombre: { fontSize: 16, fontWeight: '600', color: Colores.texto },
  coords: { fontSize: 13, color: Colores.textoSuave, marginTop: 2 },
  vacio: { alignItems: 'center', marginTop: 60, gap: 6 },
  textoVacio: { fontSize: 16, color: Colores.texto },
  ayuda: { color: Colores.textoSuave, textAlign: 'center' },
  fab: {
    position: 'absolute', right: 20, bottom: 20, width: 60, height: 60, borderRadius: 30,
    backgroundColor: Colores.primario, alignItems: 'center', justifyContent: 'center', elevation: 4,
  },
});
