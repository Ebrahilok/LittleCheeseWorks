import { useEffect, useState } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useRobot } from '@/features/robot/RobotContext';
import { distancia, esFalla, ETIQUETA_ESTADO } from '@/features/robot/modelo';
import { BandaReconexion } from '@/shared/components/BarraRobot';
import { Aviso, BotonAccion, CampoTexto, Tarjeta } from '@/shared/components/Ui';
import { COLOR_ESTADO, Colores } from '@/constants/Theme';

export default function Robot() {
  const r = useRobot();
  const st = r.status;
  const [ip, setIp] = useState('');
  const [ocupado, setOcupado] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    r.ultimaIp().then(setIp);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const ejecutar = async (f: () => Promise<void>) => {
    setOcupado(true);
    setError(null);
    try {
      await f();
    } catch {
      setError('No se pudo conectar. Revisa que el teléfono esté en la red WiFi del robot y que la IP sea correcta.');
    } finally {
      setOcupado(false);
    }
  };

  const activo = r.conectado || r.reconectando;
  const color = COLOR_ESTADO[st.estado];

  return (
    <View style={{ flex: 1 }}>
      <BandaReconexion />
      <ScrollView contentContainerStyle={e.contenido}>
        {/* Conexión */}
        <Tarjeta>
          <View style={e.filaIcono}>
            {r.reconectando ? <ActivityIndicator color={Colores.primario} /> : (
              <Ionicons name={r.conectado ? 'checkmark-circle' : 'link'} size={24} color={r.conectado ? Colores.exito : Colores.textoSuave} />
            )}
            <Text style={e.tituloTarjeta}>
              {r.reconectando ? 'Conexión perdida: reconectando…'
                : r.conectado ? (r.simulado ? 'Conectado (robot simulado)' : 'Conectado al robot') : 'Sin conexión'}
            </Text>
          </View>
          {!activo && (
            <>
              <CampoTexto etiqueta="IP del robot (ESP32)" value={ip} onChangeText={setIp} keyboardType="url"
                autoCapitalize="none" ayuda="WebSocket en el puerto 81" style={{ marginTop: 12 }} />
              <BotonAccion titulo="Conectar al robot" icono="wifi" cargando={ocupado}
                onPress={() => (ip.trim() ? ejecutar(() => r.conectarReal(ip.trim())) : setError('Escribe la IP del robot.'))} />
              <BotonAccion titulo="Modo simulación" icono="flask" variante="contorno" deshabilitado={ocupado}
                onPress={() => ejecutar(r.conectarSimulado)} estilo={{ marginTop: 8 }} />
            </>
          )}
          {activo && <BotonAccion titulo="Desconectar" variante="texto" onPress={r.desconectar} estilo={{ marginTop: 4 }} />}
          {error && <View style={{ marginTop: 12 }}><Aviso texto={error} /></View>}
        </Tarjeta>

        {r.conectado && (
          <>
            {/* Calibración */}
            <Tarjeta estilo={{ marginTop: 12 }}>
              <Text style={e.tituloTarjeta}>Preparar el robot</Text>
              {st.estado === 'ESPERANDO_CARGA' ? (
                <>
                  <Text style={e.texto}>
                    1. Deja el robot en la base.{'\n'}2. Pon la carga sobre la bandeja.{'\n'}3. Pulsa Calibrar: ese punto será el origen (0, 0) del mapa.
                  </Text>
                  <BotonAccion titulo="Ya puse la carga: Calibrar" icono="locate" onPress={r.calibrar} estilo={{ marginTop: 12 }} />
                </>
              ) : st.calibrado ? (
                <Text style={e.texto}>Calibrado. {st.conCarga ? 'Lleva carga.' : 'Sin carga.'} Ve a la pestaña Mapa para elegir el destino.</Text>
              ) : (
                <Text style={e.texto}>El robot no está calibrado. Pulsa Reiniciar.</Text>
              )}
            </Tarjeta>

            {/* Estado */}
            <View style={[e.estado, { backgroundColor: `${color}1F`, borderColor: `${color}55` }]}>
              <Text style={[e.textoEstado, { color }]}>{ETIQUETA_ESTADO[st.estado]}</Text>
              <Text style={e.texto}>Posición: ({st.x.toFixed(2)}, {st.y.toFixed(2)}) m · {st.conCarga ? 'con carga' : 'sin carga'}</Text>
              {st.destino && (
                <Text style={e.texto}>
                  Destino: ({st.destino.x.toFixed(2)}, {st.destino.y.toFixed(2)}) m · faltan {distancia(st, st.destino).toFixed(2)} m
                </Text>
              )}
            </View>

            <Tarjeta estilo={{ marginTop: 12 }}>
              <View style={e.filaIcono}>
                <Ionicons name={st.bateria <= 20 ? 'battery-dead' : 'battery-full'} size={22} color={st.bateria <= 20 ? Colores.peligro : Colores.exito} />
                <Text style={e.texto}>Batería: {st.bateria}%</Text>
              </View>
              <View style={e.barra}><View style={[e.relleno, { width: `${st.bateria}%`, backgroundColor: st.bateria <= 20 ? Colores.peligro : Colores.exito }]} /></View>
              <View style={[e.filaIcono, { marginTop: 12 }]}>
                <Ionicons name="scan" size={22} color={Colores.textoSuave} />
                <Text style={e.texto}>Objetos detectados: {r.objetos.length}</Text>
              </View>
              {st.obstaculo && (
                <View style={[e.filaIcono, { marginTop: 12 }]}>
                  <Ionicons name="warning" size={22} color={Colores.aviso} />
                  <Text style={e.texto}>Obstáculo al frente</Text>
                </View>
              )}
            </Tarjeta>

            {st.estado === 'ENTREGANDO' && (
              <BotonAccion titulo="Ya retiré la carga" icono="checkmark" onPress={r.retirarCarga} estilo={{ marginTop: 12 }} />
            )}
            {esFalla(st.estado) && (
              <BotonAccion titulo="Reiniciar" icono="refresh" variante="contorno" onPress={r.reiniciar} estilo={{ marginTop: 12 }} />
            )}

            {r.simulado && (
              <Tarjeta estilo={{ marginTop: 12 }}>
                <Text style={e.tituloTarjeta}>Controles de simulación</Text>
                <Text style={e.texto}>Mantén pulsado el mapa para poner un objeto en el camino.</Text>
                <View style={[e.filaIcono, { marginTop: 10 }]}>
                  <BotonAccion titulo="Quitar último objeto" variante="contorno" onPress={r.quitarUltimoObjeto} estilo={{ flex: 1 }} />
                  <BotonAccion titulo="Perder ubicación" variante="contorno" onPress={r.perderUbicacion} estilo={{ flex: 1 }} />
                </View>
              </Tarjeta>
            )}
          </>
        )}
      </ScrollView>
    </View>
  );
}

const e = StyleSheet.create({
  contenido: { padding: 16, paddingBottom: 32 },
  filaIcono: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  tituloTarjeta: { fontSize: 16, fontWeight: '700', color: Colores.texto, flexShrink: 1 },
  texto: { fontSize: 15, color: Colores.texto, marginTop: 4, lineHeight: 22 },
  estado: { marginTop: 12, padding: 20, borderRadius: 14, borderWidth: 1, alignItems: 'center' },
  textoEstado: { fontSize: 24, fontWeight: '800', textAlign: 'center', marginBottom: 6 },
  barra: { height: 8, backgroundColor: '#E8E4DC', borderRadius: 4, marginTop: 8, overflow: 'hidden' },
  relleno: { height: 8 },
});
