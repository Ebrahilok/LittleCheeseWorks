# App móvil (React Native con Expo)

App para mandar al robot a un punto del cuarto, ver cómo avanza en el mapa y guardar los lugares que más se usan.
Reemplaza al prototipo de Flutter (`../app-flutter/`) y sigue la arquitectura del documento de la semana 1.

**Descargar el APK:** https://github.com/Ebrahilok/LittleCheeseWorks/releases/latest

## Qué tiene

| Pestaña | Qué hace |
|---|---|
| Login / Registro | Sesión con la API (token JWT guardado con `expo-secure-store`). También hay modo demo sin servidor. |
| Mapa | Vista superior del cuarto: toca un punto y pulsa **Llevar aquí**. Dibuja el robot, el recorrido, el destino y los objetos. |
| Puntos | CRUD de puntos guardados contra la API: listado, detalle, crear, editar y eliminar. |
| Robot | Conectar al robot real (`ws://IP:81`) o al simulador, calibrar, estado, batería y controles de simulación. |
| Alertas | Batería baja, obstáculos, conexión perdida y objetos detectados. |
| Perfil | Datos de la cuenta, medidas del cuarto y cerrar sesión. |

El botón rojo **PARO** aparece arriba en todas las pestañas mientras hay robot conectado.

## Estructura

```
src/
├─ app/                  rutas de Expo Router
│  ├─ _layout.tsx        providers y rutas protegidas
│  ├─ (auth)/            login.tsx, registro.tsx
│  └─ (tabs)/            index.tsx (mapa), puntos/, robot.tsx, alertas.tsx, perfil.tsx
├─ features/
│  ├─ auth/              AuthContext, authReducer, authService
│  ├─ cuarto/            CuartoContext y cuartoApi (API real o almacenamiento local del modo demo)
│  └─ robot/             modelo y protocolo, RobotSimulado, RobotWebSocket, robotReducer, RobotContext
├─ shared/
│  ├─ api/               axiosInstance (servidor configurable, token y manejo de 401)
│  └─ components/        Ui (BotonAccion, CampoTexto, Tarjeta, Aviso), MapaCuarto, BarraRobot
└─ constants/            colores
pruebas/                 pruebas del protocolo, el simulador y el reducer (node --test)
```

## Correrla en desarrollo

```bash
npm install
npx expo start        # se abre con Expo Go o con el emulador de Android
npm test              # pruebas de la lógica del robot
npm run typecheck
```

En el celular no existe `localhost`: en el login, en **Servidor**, se escribe la IP de la computadora donde corre la API
(por ejemplo `http://192.168.1.70:5150`). En el emulador de Android es `http://10.0.2.2:5150`.

## Cómo se genera el APK

El workflow `.github/workflows/apk.yml` corre cada vez que cambia algo en `app/`:
instala dependencias, revisa los tipos, corre las pruebas, genera el proyecto Android con `expo prebuild`,
compila con Gradle y publica `PequenoQueso.apk` en Releases.
