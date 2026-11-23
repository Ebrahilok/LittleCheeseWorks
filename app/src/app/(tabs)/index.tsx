import { useState } from 'react';
import { ScrollView, StyleSheet, Text, View, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import { useRobot } from '@/features/robot/RobotContext';
import { distancia, esFalla, ETIQUETA_ESTADO } from '@/features/robot/modelo';
import type { Punto } from '@/features/robot/modelo';
import { MapaCuarto } from '@/shared/components/MapaCuarto';
import { BandaReconexion } from '@/shared/components/BarraRobot';
import { BotonAccion, Tarjeta } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

export default function Mapa() {
  const robot = useRobot();
  const { cuarto, puntos } = useCuarto();
  const [seleccionado, setSeleccionado] = useState<Punto | null>(null);
  const st = robot.status;

  // Se puede mandar en cualquier momento si el robot está calibrado y sin falla
  const robotListo = robot.conectado && st.calibrado && !esFalla(st.estado);
  const puedeEnviar = robotListo && seleccionado !== null;

  const motivo = !robot.conectado
    ? 'Conéctate al robot o usa el simulador en la pestaña Robot.'
    : !st.calibrado
      ? 'Primero calibra el robot en la base (pestaña Robot).'
      : esFalla(st.estado)
        ? `El robot está en ${ETIQUETA_ESTADO[st.estado]}: pulsa Reiniciar en la pestaña Robot.`
        : 'Toca el mapa o un punto guardado para elegir el destino.';

  return (
    <View style={{ flex: 1 }}>
      <BandaReconexion />
      <ScrollView contentContainerStyle={e.contenido}>
        <MapaCuarto
          cuarto={cuarto}
          status={robot.conectado ? st : null}
          objetos={robot.objetos}
          puntos={puntos}
          recorrido={robot.recorrido}
          seleccionado={seleccionado}
          onTocar={setSeleccionado}
          onMantener={robot.simulado ? robot.colocarObjeto : undefined}
          altoMax={440}
        />

        <Tarjeta estilo={{ marginTop: 12 }}>
          <Text style={e.destino}>
            {seleccionado
              ? `Destino: (${seleccionado.x.toFixed(2)}, ${seleccionado.y.toFixed(2)}) m${robot.conectado ? ` · a ${distancia(seleccionado, st).toFixed(2)} m del robot` : ''}`
              : 'Toca el mapa para elegir el destino'}
          </Text>

          {puntos.length > 0 && (
            <View style={e.chips}>
              {puntos.map((p) => (
                <Pressable key={p.id} onPress={() => setSeleccionado({ x: p.x, y: p.y })} style={e.chip}>
                  <Text style={e.textoChip}>{p.nombre}</Text>
                </Pressable>
              ))}
            </View>
          )}

          <View style={e.fila}>
            <BotonAccion titulo="Llevar aquí" icono="send" onPress={() => robot.irA(seleccionado!)}
              deshabilitado={!puedeEnviar} estilo={{ flex: 1 }} />
            <BotonAccion titulo="Guardar" icono="bookmark-outline" variante="contorno" deshabilitado={!seleccionado}
              onPress={() => router.push({
                pathname: '/puntos/formulario',
                params: { x: seleccionado!.x.toFixed(2), y: seleccionado!.y.toFixed(2) },
              })} />
          </View>
          {!puedeEnviar && <Text style={e.nota}>{motivo}</Text>}
          {robot.simulado && <Text style={e.nota}>Simulación: mantén pulsado el mapa para poner un objeto.</Text>}
        </Tarjeta>
      </ScrollView>
    </View>
  );
}

const e = StyleSheet.create({
  contenido: { padding: 12, paddingBottom: 24 },
  destino: { fontSize: 15, color: Colores.texto, fontWeight: '600' },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 10 },
  chip: {
    paddingHorizontal: 12, paddingVertical: 7, borderRadius: 16,
    backgroundColor: '#F3E5F5', borderWidth: 1, borderColor: '#E1BEE7',
  },
  textoChip: { color: Colores.punto, fontWeight: '600' },
  fila: { flexDirection: 'row', gap: 8, marginTop: 12 },
  nota: { color: Colores.textoSuave, fontSize: 13, marginTop: 8 },
});
