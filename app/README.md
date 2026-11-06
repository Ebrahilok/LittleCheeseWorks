# App Robot Mesero (Flutter)

App móvil (Android/iOS) para controlar el robot mesero. Ver `../docs/especificaciones.md` §4.

## Ejecutar
```
flutter pub get
flutter run            # elige dispositivo/emulador
flutter test
```
En la pestaña **Conexión** usa **Modo simulación** para probar sin hardware
(botones para poner/quitar obstáculo y perder la línea en la pestaña Estado).

## Robot real
El ESP32 debe exponer un servidor WebSocket en el puerto 81 (`ws://<ip>:81`)
y enviar estados al menos cada 1-2 s (si pasan 5 s sin mensajes, la app marca la conexión como perdida).

### Protocolo (JSON)
App → Robot: `{"cmd":"go","table":3}`, `{"cmd":"confirm"}`, `{"cmd":"stop"}`, `{"cmd":"reset"}`
Robot → App: `{"state":"EN_RUTA","table":3,"battery":78,"obstacle":false}`,
`{"event":"error","code":"LINE_LOST"}`

Estados: REPOSO, EN_RUTA, OBSTACULO, ESPERANDO, REGRESANDO, ERROR, PARO.
Códigos de evento: LINE_LOST, LOW_BATTERY, OBSTACLE_TIMEOUT.

> `reset` es una adición al protocolo de la especificación (reinicio manual desde ERROR/PARO).
