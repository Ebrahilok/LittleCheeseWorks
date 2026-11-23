import { useCallback, useState } from 'react';
import { ActivityIndicator, Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import { router, useFocusEffect, useLocalSearchParams } from 'expo-router';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import type { PuntoGuardado } from '@/features/cuarto/cuartoApi';
import { useRobot } from '@/features/robot/RobotContext';
import { esFalla } from '@/features/robot/modelo';
import { MapaCuarto } from '@/shared/components/MapaCuarto';
import { Aviso, BotonAccion, Tarjeta } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

export default function DetallePunto() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { cuarto, obtenerPunto, eliminarPunto } = useCuarto();
  const robot = useRobot();
  const [punto, setPunto] = useState<PuntoGuardado | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Se vuelve a pedir al servidor cada vez que la pantalla se muestra (por si se editó)
  useFocusEffect(useCallback(() => {
    obtenerPunto(Number(id)).then(setPunto).catch((e: Error) => setError(e.message));
  }, [id, obtenerPunto]));

  const borrar = () => {
    Alert.alert('Eliminar punto', `¿Seguro que quieres eliminar "${punto?.nombre}"?`, [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Eliminar', style: 'destructive',
        onPress: async () => {
          try {
            await eliminarPunto(Number(id));
            router.back();
          } catch (e) {
            setError((e as Error).message);
          }
        },
      },
    ]);
  };

  if (error && !punto) return <View style={{ padding: 16 }}><Aviso texto={error} /></View>;
  if (!punto) return <ActivityIndicator style={{ marginTop: 40 }} color={Colores.primario} />;

  const puedeEnviar = robot.conectado && robot.status.calibrado && !esFalla(robot.status.estado);
  const fecha = new Date(punto.fechaCreacion).toLocaleString('es-MX', { dateStyle: 'medium', timeStyle: 'short' });

  return (
    <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 32 }}>
      {error && <Aviso texto={error} />}
      <Tarjeta>
        <Text style={e.nombre}>{punto.nombre}</Text>
        <Dato etiqueta="Desde la base" valor={`x ${punto.x.toFixed(2)} m · y ${punto.y.toFixed(2)} m`} />
        <Dato etiqueta="Distancia a la base" valor={`${Math.hypot(punto.x, punto.y).toFixed(2)} m`} />
        <Dato etiqueta="Cuarto" valor={`${cuarto.nombre} (${cuarto.ancho} × ${cuarto.largo} m)`} />
        <Dato etiqueta="Creado" valor={fecha} />
      </Tarjeta>

      <View style={{ marginTop: 12 }}>
        <MapaCuarto cuarto={cuarto} puntos={[punto]} seleccionado={punto} altoMax={260} />
      </View>

      <BotonAccion titulo="Llevar carga aquí" icono="send" deshabilitado={!puedeEnviar} estilo={{ marginTop: 16 }}
        onPress={() => {
          robot.irA(punto);
          router.navigate('/');
        }} />
      {!puedeEnviar && <Text style={e.nota}>Conecta y calibra el robot en la pestaña Robot para mandarlo aquí.</Text>}
      <View style={e.fila}>
        <BotonAccion titulo="Editar" icono="create-outline" variante="contorno" estilo={{ flex: 1 }}
          onPress={() => router.push({ pathname: '/puntos/formulario', params: { id: String(punto.id) } })} />
        <BotonAccion titulo="Eliminar" icono="trash-outline" variante="peligro" estilo={{ flex: 1 }} onPress={borrar} />
      </View>
    </ScrollView>
  );
}

function Dato({ etiqueta, valor }: { etiqueta: string; valor: string }) {
  return (
    <View style={e.dato}>
      <Text style={e.etiqueta}>{etiqueta}</Text>
      <Text style={e.valor}>{valor}</Text>
    </View>
  );
}

const e = StyleSheet.create({
  nombre: { fontSize: 22, fontWeight: '800', color: Colores.texto, marginBottom: 8 },
  dato: { paddingVertical: 8, borderTopWidth: 1, borderColor: '#F0EBE3' },
  etiqueta: { fontSize: 13, color: Colores.textoSuave },
  valor: { fontSize: 16, color: Colores.texto, marginTop: 2 },
  nota: { color: Colores.textoSuave, fontSize: 13, marginTop: 6 },
  fila: { flexDirection: 'row', gap: 10, marginTop: 12 },
});
