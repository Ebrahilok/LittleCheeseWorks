import { useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Link } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '@/features/auth/AuthContext';
import { mensajeDeError, servidorActual } from '@/shared/api/axiosInstance';
import { Aviso, BotonAccion, CampoTexto } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

const CORREO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function Registro() {
  const { signUp } = useAuth();
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmar, setConfirmar] = useState('');
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(false);

  // Mismas reglas que los DTOs del backend
  const crear = async () => {
    const e: Record<string, string> = {};
    if (nombre.trim().length < 2) e.nombre = 'El nombre debe tener al menos 2 caracteres.';
    if (!CORREO.test(email.trim())) e.email = 'Escribe un correo válido.';
    if (password.length < 8) e.password = 'La contraseña debe tener al menos 8 caracteres.';
    if (confirmar !== password) e.confirmar = 'Las contraseñas no coinciden.';
    setErrores(e);
    if (Object.keys(e).length) return;
    setCargando(true);
    setError(null);
    try {
      await signUp({ nombre, email, password });
    } catch (err) {
      setError(mensajeDeError(err));
      setCargando(false);
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: Colores.fondo }}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={{ padding: 24 }} keyboardShouldPersistTaps="handled">
          <Text style={e.titulo}>Crear cuenta</Text>
          <Text style={e.subtitulo}>Las cuentas nuevas entran como Operador.</Text>
          {error && <Aviso texto={error} />}
          <CampoTexto etiqueta="Nombre" value={nombre} onChangeText={setNombre} error={errores.nombre} autoComplete="name" />
          <CampoTexto etiqueta="Correo" value={email} onChangeText={setEmail} error={errores.email}
            keyboardType="email-address" autoCapitalize="none" autoComplete="email" />
          <CampoTexto etiqueta="Contraseña" value={password} onChangeText={setPassword} error={errores.password}
            secureTextEntry ayuda="Mínimo 8 caracteres." />
          <CampoTexto etiqueta="Confirmar contraseña" value={confirmar} onChangeText={setConfirmar}
            error={errores.confirmar} secureTextEntry onSubmitEditing={crear} />
          <Text style={e.servidor}>Servidor: {servidorActual()}</Text>
          <BotonAccion titulo="Crear cuenta" onPress={crear} cargando={cargando} />
          <View style={e.fila}>
            <Text style={{ color: Colores.textoSuave }}>¿Ya tienes cuenta? </Text>
            <Link href="/login" style={e.link}>Inicia sesión</Link>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const e = StyleSheet.create({
  titulo: { fontSize: 26, fontWeight: '800', color: Colores.texto, marginTop: 16 },
  subtitulo: { color: Colores.textoSuave, marginTop: 4, marginBottom: 20 },
  servidor: { color: Colores.textoSuave, fontSize: 13, marginBottom: 12 },
  fila: { flexDirection: 'row', justifyContent: 'center', marginTop: 18 },
  link: { color: Colores.primarioOscuro, fontWeight: '700' },
});
