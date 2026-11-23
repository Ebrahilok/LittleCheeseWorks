import { useEffect, useState } from 'react';
import { KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Link } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '@/features/auth/AuthContext';
import { cargarServidor, guardarServidor, mensajeDeError } from '@/shared/api/axiosInstance';
import { Aviso, BotonAccion, CampoTexto } from '@/shared/components/Ui';
import { Colores } from '@/constants/Theme';

const CORREO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function Login() {
  const { signIn, entrarDemo } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [servidor, setServidor] = useState('');
  const [verServidor, setVerServidor] = useState(false);
  const [errores, setErrores] = useState<{ email?: string; password?: string }>({});
  const [error, setError] = useState<string | null>(null);
  const [cargando, setCargando] = useState(false);

  useEffect(() => {
    cargarServidor().then(setServidor);
  }, []);

  const entrar = async () => {
    const e: typeof errores = {};
    if (!CORREO.test(email.trim())) e.email = 'Escribe un correo válido.';
    if (!password) e.password = 'Escribe tu contraseña.';
    setErrores(e);
    if (Object.keys(e).length) return;
    setCargando(true);
    setError(null);
    try {
      await guardarServidor(servidor);
      await signIn({ email, password });
    } catch (err) {
      setError(mensajeDeError(err));
      setCargando(false);
    }
  };

  return (
    <SafeAreaView style={e.pantalla}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
        <ScrollView contentContainerStyle={e.contenido} keyboardShouldPersistTaps="handled">
          <View style={e.logo}>
            <Ionicons name="cube" size={44} color={Colores.primario} />
          </View>
          <Text style={e.titulo}>El Pequeño Queso Trabaja</Text>
          <Text style={e.subtitulo}>Inicia sesión para mandar cargas con el robot.</Text>

          {error && <Aviso texto={error} />}

          <CampoTexto etiqueta="Correo" value={email} onChangeText={setEmail} error={errores.email}
            keyboardType="email-address" autoCapitalize="none" autoComplete="email" placeholder="tu@correo.com" />
          <CampoTexto etiqueta="Contraseña" value={password} onChangeText={setPassword} error={errores.password}
            secureTextEntry autoComplete="password" onSubmitEditing={entrar} />

          <Pressable onPress={() => setVerServidor((v) => !v)} style={e.servidorFila}>
            <Ionicons name={verServidor ? 'chevron-down' : 'chevron-forward'} size={16} color={Colores.textoSuave} />
            <Text style={e.servidorTexto}>Servidor: {servidor}</Text>
          </Pressable>
          {verServidor && (
            <CampoTexto etiqueta="Dirección de la API" value={servidor} onChangeText={setServidor}
              autoCapitalize="none" keyboardType="url"
              ayuda="IP de la computadora donde corre la API, por ejemplo http://192.168.1.70:5150" />
          )}

          <BotonAccion titulo="Entrar" onPress={entrar} cargando={cargando} estilo={{ marginTop: 8 }} />

          <View style={e.registro}>
            <Text style={{ color: Colores.textoSuave }}>¿No tienes cuenta? </Text>
            <Link href="/registro" style={e.link}>Regístrate</Link>
          </View>

          <View style={e.separador} />
          <BotonAccion titulo="Probar sin servidor (modo demo)" variante="contorno" icono="flask" onPress={entrarDemo} />
          <Text style={e.notaDemo}>En modo demo el robot es simulado y los puntos se guardan solo en este teléfono.</Text>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const e = StyleSheet.create({
  pantalla: { flex: 1, backgroundColor: Colores.fondo },
  contenido: { padding: 24, paddingTop: 40 },
  logo: {
    width: 76, height: 76, borderRadius: 22, backgroundColor: Colores.primarioSuave,
    alignItems: 'center', justifyContent: 'center', alignSelf: 'center', marginBottom: 16,
  },
  titulo: { fontSize: 24, fontWeight: '800', textAlign: 'center', color: Colores.texto },
  subtitulo: { fontSize: 15, textAlign: 'center', color: Colores.textoSuave, marginTop: 6, marginBottom: 24 },
  servidorFila: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingVertical: 8, marginBottom: 4 },
  servidorTexto: { color: Colores.textoSuave, fontSize: 13, flex: 1 },
  registro: { flexDirection: 'row', justifyContent: 'center', marginTop: 18 },
  link: { color: Colores.primarioOscuro, fontWeight: '700' },
  separador: { height: 1, backgroundColor: Colores.borde, marginVertical: 24 },
  notaDemo: { color: Colores.textoSuave, fontSize: 13, textAlign: 'center', marginTop: 8 },
});
