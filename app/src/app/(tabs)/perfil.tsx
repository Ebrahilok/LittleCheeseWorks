import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '@/features/auth/AuthContext';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import { useRobot } from '@/features/robot/RobotContext';
import { CUARTO_CLASE, CUARTO_ESTANDAR } from '@/features/robot/modelo';
import type { Cuarto } from '@/features/robot/modelo';
import { servidorActual } from '@/shared/api/axiosInstance';
import { Aviso, BotonAccion, CampoTexto, Tarjeta } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

const aTexto = (n: number) => String(Number(n.toFixed(2)));
const aNumero = (t: string) => Number(t.trim().replace(',', '.'));

export default function Perfil() {
  const { sesion, logOut } = useAuth();
  const { cuarto, guardarCuarto } = useCuarto();
  const robot = useRobot();
  const [campos, setCampos] = useState({ ancho: '', largo: '', baseX: '', baseY: '' });
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const [guardando, setGuardando] = useState(false);

  const llenar = (c: Cuarto) => setCampos({ ancho: aTexto(c.ancho), largo: aTexto(c.largo), baseX: aTexto(c.baseX), baseY: aTexto(c.baseY) });
  useEffect(() => llenar(cuarto), [cuarto]);

  const guardar = async () => {
    const valores = { ancho: aNumero(campos.ancho), largo: aNumero(campos.largo), baseX: aNumero(campos.baseX), baseY: aNumero(campos.baseY) };
    if (Object.values(valores).some((v) => !Number.isFinite(v))) {
      setError('Escribe las cuatro medidas en metros.');
      return;
    }
    setGuardando(true);
    setError(null);
    setOk(false);
    try {
      await guardarCuarto({ ...cuarto, ...valores });
      setOk(true);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setGuardando(false);
    }
  };

  const salir = () => {
    robot.desconectar();
    void logOut();
  };

  const campo = (clave: keyof typeof campos, etiqueta: string) => (
    <View style={{ flex: 1 }}>
      <CampoTexto etiqueta={etiqueta} value={campos[clave]} keyboardType="decimal-pad"
        onChangeText={(t) => setCampos((c) => ({ ...c, [clave]: t }))} />
    </View>
  );

  return (
    <ScrollView contentContainerStyle={e.contenido} keyboardShouldPersistTaps="handled">
      <Tarjeta>
        <View style={e.fila}>
          <View style={e.avatar}><Ionicons name="person" size={28} color={Colores.primario} /></View>
          <View style={{ flex: 1 }}>
            <Text style={e.nombre}>{sesion?.usuario.nombre}</Text>
            <Text style={e.suave}>{sesion?.usuario.email}</Text>
            <Text style={e.rol}>{sesion?.modo === 'demo' ? 'Modo demo (sin servidor)' : sesion?.usuario.rol}</Text>
          </View>
        </View>
        {sesion?.modo === 'api' && <Text style={[e.suave, { marginTop: 10 }]}>Servidor: {servidorActual()}</Text>}
      </Tarjeta>

      <Tarjeta estilo={{ marginTop: 12 }}>
        <Text style={e.titulo}>Medidas del cuarto</Text>
        <Text style={[e.suave, { marginBottom: 12 }]}>Mide el cuarto y dónde va la base (el punto de partida del robot).</Text>
        <View style={[e.fila, { marginBottom: 12 }]}>
          <Pressable style={e.chip} onPress={() => llenar(CUARTO_CLASE)}><Text style={e.textoChip}>Clase: 2 × 2 m</Text></Pressable>
          <Pressable style={e.chip} onPress={() => llenar(CUARTO_ESTANDAR)}><Text style={e.textoChip}>Grande: 6 × 4 m</Text></Pressable>
        </View>
        <View style={e.fila}>{campo('ancho', 'Ancho (m)')}{campo('largo', 'Largo (m)')}</View>
        <View style={e.fila}>{campo('baseX', 'Base desde la izquierda')}{campo('baseY', 'Base desde arriba')}</View>
        {error && <Aviso texto={error} />}
        {ok && <Aviso texto="Medidas guardadas." tipo="info" />}
        <BotonAccion titulo="Guardar medidas" onPress={guardar} cargando={guardando} />
      </Tarjeta>

      <BotonAccion titulo="Cerrar sesión" icono="log-out-outline" variante="contorno" onPress={salir} estilo={{ marginTop: 20 }} />
    </ScrollView>
  );
}

const e = StyleSheet.create({
  contenido: { padding: 16, paddingBottom: 32 },
  fila: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  avatar: { width: 54, height: 54, borderRadius: 27, backgroundColor: Colores.primarioSuave, alignItems: 'center', justifyContent: 'center' },
  nombre: { fontSize: 18, fontWeight: '700', color: Colores.texto },
  suave: { color: Colores.textoSuave, fontSize: 14 },
  rol: { color: Colores.primarioOscuro, fontWeight: '600', marginTop: 2 },
  titulo: { fontSize: 16, fontWeight: '700', color: Colores.texto, marginBottom: 4 },
  chip: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 16, backgroundColor: Colores.primarioSuave },
  textoChip: { color: Colores.primarioOscuro, fontWeight: '600' },
});
