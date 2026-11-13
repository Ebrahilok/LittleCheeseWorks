# App Robot de Carga (Flutter)

App (Android/iOS/escritorio/web) para controlar el robot que lleva objetos a un punto del cuarto.
Ver `../docs/especificaciones.md` §4.

## Ejecutar
```
flutter pub get
flutter run -d chrome     # o windows / un emulador o teléfono
flutter test
```
Pestaña **Preparar** → **Modo simulación** → *Calibrar* → pestaña **Mapa**: toca un punto y pulsa *Llevar aquí*.
En simulación, **mantén pulsado** el mapa para colocar un objeto; el robot lo detecta y se detiene si está en su camino
(pestaña **Estado** → *Quitar último objeto*). La pestaña **3D** muestra el cuarto (arrastrar = girar, rueda/pellizco = zoom).

## Flujo
1. Robot en la base con la carga encima → **Calibrar**: ese punto es el origen (0, 0).
2. Elegir destino en el mapa (o un punto guardado) → **Llevar aquí**.
3. En el destino espera el retiro de la carga → **Ya retiré la carga** (o 60 s) → regresa a la base. Mientras el robot esté calibrado y sin falla (también en el destino, regresando o ya en la base) puedes elegir otro punto y pulsar **Llevar aquí** sin parar el robot; sin carga solo va al punto y queda en *Listo*.

## Ajustes que la app recuerda
- **Cuarto:** en *Preparar* → tarjeta *Cuarto* se escriben el ancho y el largo del cuarto y a qué distancia de las paredes
  izquierda y superior está la base. El mapa, el visor 3D y el simulador usan esas medidas (por defecto 6 × 4 m).
  Hay dos botones rápidos: **Clase: 2 × 2 m** (base a 25 cm de las paredes) y **Grande: 6 × 4 m**.
- **Puntos guardados** e **IP del robot**: se conservan al cerrar la app (`shared_preferences`).

En el mapa se dibuja el **recorrido** que lleva el robot desde que salió de la base y la distancia al destino elegido.

## Robot real
El ESP32 debe exponer un servidor WebSocket en el puerto 81 (`ws://<ip>:81`) y enviar su estado al menos cada 1–2 s
(5 s sin mensajes = conexión perdida).

Si la conexión se cae, la app avisa una vez (banda roja "Reconectando…" y una alerta) y **reintenta sola** cada 1–8 s
hasta recuperar al robot o hasta pulsar *Desconectar*. Mientras no hay conexión los comandos no se envían (incluido
PARO): el firmware debe detener los motores por su cuenta al perder a la app, y el paro físico siempre funciona.
El primer intento sí muestra error si la IP es incorrecta o el robot está apagado.

Cableado del robot y sketch de prueba: `../docs/tutorial_conexion.md`.

### Protocolo (JSON)
App → Robot: `{"cmd":"calibrate"}`, `{"cmd":"goto","x":2.5,"y":1.0}`, `{"cmd":"unload"}`, `{"cmd":"stop"}`, `{"cmd":"reset"}`

Robot → App:
```
{"state":"EN_RUTA","x":1.2,"y":0.4,"heading":0.35,"load":true,"calibrated":true,
 "target":{"x":2.5,"y":1.0},"battery":78,"obstacle":false}
{"event":"object","id":3,"x":1.8,"y":0.9,"w":0.3,"h":0.3}
{"event":"object_gone","id":3}
{"event":"error","code":"LOCALIZATION_LOST"}
```
Metros respecto a la base; +x a la derecha, +y hacia abajo (vista superior); `heading` en radianes.
Estados: ESPERANDO_CARGA, LISTO, EN_RUTA, OBSTACULO, ENTREGANDO, REGRESANDO, ERROR, PARO.
Errores: LOCALIZATION_LOST, LOW_BATTERY, OBSTACLE_TIMEOUT.

El cuarto por defecto mide 6 × 4 m con la base a 0.5 m de cada pared (`Room.standard` en `lib/models/world.dart`).
