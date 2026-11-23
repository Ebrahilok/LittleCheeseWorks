import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import type { ReactNode } from 'react';
import type { StyleProp, TextInputProps, ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colores } from '@/constants/Theme';

type Variante = 'primario' | 'contorno' | 'peligro' | 'texto';

interface BotonProps {
  titulo: string;
  onPress: () => void;
  variante?: Variante;
  icono?: keyof typeof Ionicons.glyphMap;
  deshabilitado?: boolean;
  cargando?: boolean;
  estilo?: StyleProp<ViewStyle>;
}

export function BotonAccion({ titulo, onPress, variante = 'primario', icono, deshabilitado, cargando, estilo }: BotonProps) {
  const inactivo = deshabilitado || cargando;
  const color = variante === 'primario' || variante === 'peligro' ? '#fff' : variante === 'texto' ? Colores.primarioOscuro : Colores.primario;
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      disabled={inactivo}
      style={({ pressed }) => [
        e.boton,
        variante === 'primario' && { backgroundColor: Colores.primario },
        variante === 'peligro' && { backgroundColor: Colores.peligro },
        variante === 'contorno' && { borderWidth: 1.5, borderColor: Colores.primario, backgroundColor: '#fff' },
        variante === 'texto' && { backgroundColor: 'transparent' },
        pressed && { opacity: 0.8 },
        inactivo && { opacity: 0.45 },
        estilo,
      ]}
    >
      {cargando ? <ActivityIndicator color={color} /> : (
        <>
          {icono && <Ionicons name={icono} size={18} color={color} />}
          <Text style={[e.textoBoton, { color }]}>{titulo}</Text>
        </>
      )}
    </Pressable>
  );
}

interface CampoProps extends TextInputProps {
  etiqueta: string;
  error?: string | null;
  ayuda?: string;
}

export function CampoTexto({ etiqueta, error, ayuda, style, ...props }: CampoProps) {
  return (
    <View style={e.campo}>
      <Text style={e.etiqueta}>{etiqueta}</Text>
      <TextInput
        placeholderTextColor="#9AA0A6"
        style={[e.input, error ? { borderColor: Colores.peligro } : null, style]}
        {...props}
      />
      {error ? <Text style={e.error}>{error}</Text> : ayuda ? <Text style={e.ayuda}>{ayuda}</Text> : null}
    </View>
  );
}

export function Tarjeta({ children, estilo }: { children: ReactNode; estilo?: StyleProp<ViewStyle> }) {
  return <View style={[e.tarjeta, estilo]}>{children}</View>;
}

export function Aviso({ texto, tipo = 'error' }: { texto: string; tipo?: 'error' | 'info' }) {
  return (
    <View style={[e.aviso, tipo === 'info' && { backgroundColor: Colores.primarioSuave, borderColor: '#F6C7A6' }]}>
      <Ionicons name={tipo === 'error' ? 'alert-circle' : 'information-circle'} size={18}
        color={tipo === 'error' ? Colores.peligro : Colores.primarioOscuro} />
      <Text style={[e.textoAviso, tipo === 'info' && { color: Colores.texto }]}>{texto}</Text>
    </View>
  );
}

const e = StyleSheet.create({
  boton: {
    minHeight: 48, borderRadius: 12, paddingHorizontal: 16, flexDirection: 'row',
    alignItems: 'center', justifyContent: 'center', gap: 8,
  },
  textoBoton: { fontSize: 16, fontWeight: '600' },
  campo: { marginBottom: 14 },
  etiqueta: { fontSize: 14, fontWeight: '600', color: Colores.texto, marginBottom: 6 },
  input: {
    minHeight: 48, borderWidth: 1, borderColor: Colores.borde, borderRadius: 10,
    paddingHorizontal: 12, fontSize: 16, backgroundColor: '#fff', color: Colores.texto,
  },
  error: { color: Colores.peligro, fontSize: 13, marginTop: 4 },
  ayuda: { color: Colores.textoSuave, fontSize: 13, marginTop: 4 },
  tarjeta: {
    backgroundColor: Colores.tarjeta, borderRadius: 14, padding: 16, borderWidth: 1, borderColor: '#ECE7DF',
  },
  aviso: {
    flexDirection: 'row', gap: 8, alignItems: 'flex-start', padding: 12, borderRadius: 10,
    backgroundColor: Colores.peligroSuave, borderWidth: 1, borderColor: '#F5C2BE', marginBottom: 12,
  },
  textoAviso: { flex: 1, color: Colores.peligro, fontSize: 14 },
});
