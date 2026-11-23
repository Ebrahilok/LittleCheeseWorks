import { useEffect, useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, Text, View } from 'react-native';
import { router, useLocalSearchParams, useNavigation } from 'expo-router';
import { useCuarto } from '@/features/cuarto/CuartoContext';
import { dentroDelCuarto, limites } from '@/features/robot/modelo';
import type { Punto } from '@/features/robot/modelo';
import { MapaCuarto } from '@/shared/components/MapaCuarto';
import { Aviso, BotonAccion, CampoTexto } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

const aNumero = (t: string) => Number(t.trim().replace(',', '.'));

/** Crear (sin id) o editar (con id) un punto. Las coordenadas se escriben o se tocan en el mapa. */
export default function FormularioPunto() {
  const params = useLocalSearchParams<{ id?: string; x?: string; y?: string }>();
  const editando = params.id !== undefined;
  const navigation = useNavigation();
  const { cuarto, puntos, crearPunto, editarPunto } = useCuarto();
  const [nombre, setNombre] = useState('');
  const [x, setX] = useState(params.x ?? '');
  const [y, setY] = useState(params.y ?? '');
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [guardando, setGuardando] = useState(false);

  useEffect(() => {
    navigation.setOptions({ title: editando ? 'Editar punto' : 'Nuevo punto' });
    if (editando) {
      const p = puntos.find((q) => q.id === Number(params.id));
      if (p) {
        setNombre(p.nombre);
        setX(p.x.toFixed(2));
        setY(p.y.toFixed(2));
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const actual: Punto | null = Number.isFinite(aNumero(x)) && Number.isFinite(aNumero(y)) && x !== '' && y !== ''
    ? { x: aNumero(x), y: aNumero(y) } : null;
  const l = limites(cuarto);

  const guardar = async () => {
    const e: Record<string, string> = {};
    if (!nombre.trim()) e.nombre = 'Escribe un nombre.';
    else if (nombre.trim().length > 80) e.nombre = 'Máximo 80 caracteres.';
    if (!actual) e.coords = 'Escribe las dos coordenadas o toca el mapa.';
    else if (!dentroDelCuarto(cuarto, actual)) e.coords = 'El punto queda fuera del cuarto.';
    setErrores(e);
    if (Object.keys(e).length) return;
    setGuardando(true);
    setError(null);
    try {
      if (editando) await editarPunto(Number(params.id), nombre, actual!);
      else await crearPunto(nombre, actual!);
      router.back();
    } catch (err) {
      setError((err as Error).message);
      setGuardando(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 32 }} keyboardShouldPersistTaps="handled">
        {error && <Aviso texto={error} />}
        <CampoTexto etiqueta="Nombre" value={nombre} onChangeText={setNombre} error={errores.nombre}
          placeholder="Por ejemplo: Escritorio" maxLength={80} />
        <View style={{ flexDirection: 'row', gap: 10 }}>
          <View style={{ flex: 1 }}>
            <CampoTexto etiqueta="x (m)" value={x} onChangeText={setX} keyboardType="numbers-and-punctuation" />
          </View>
          <View style={{ flex: 1 }}>
            <CampoTexto etiqueta="y (m)" value={y} onChangeText={setY} keyboardType="numbers-and-punctuation" />
          </View>
        </View>
        <Text style={{ color: errores.coords ? Colores.peligro : Colores.textoSuave, fontSize: 13, marginTop: -6, marginBottom: 10 }}>
          {errores.coords ?? `Medido desde la base. x entre ${l.minX} y ${l.maxX}, y entre ${l.minY} y ${l.maxY}. También puedes tocar el mapa.`}
        </Text>
        <MapaCuarto cuarto={cuarto} puntos={puntos.filter((p) => p.id !== Number(params.id))} seleccionado={actual}
          onTocar={(p) => { setX(p.x.toFixed(2)); setY(p.y.toFixed(2)); }} altoMax={300} />
        <BotonAccion titulo={editando ? 'Guardar cambios' : 'Guardar punto'} onPress={guardar} cargando={guardando}
          estilo={{ marginTop: 16 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
