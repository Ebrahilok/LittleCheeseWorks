# LittleCheeseWorks: robot autónomo de transporte de carga

Robot móvil de bajo costo que lleva objetos desde una base hasta un punto elegido en una app móvil.
Proyecto de la Universidad Autónoma de Occidente.

![Prototipo del robot](docs/img/robot_prototipo_frente.png)

| Qué | Dónde |
|---|---|
| Especificaciones del proyecto | [`docs/especificaciones.md`](docs/especificaciones.md) |
| Presupuesto con enlaces de compra y reparto entre 4 | [`docs/presupuesto.md`](docs/presupuesto.md) |
| Tutorial de armado y conexión del ESP32 | [`docs/tutorial_conexion.md`](docs/tutorial_conexion.md) |
| **Versión de clase: robot mini para 2 × 2 m (~$215 por persona)** | [`docs/robot_mini_2x2.md`](docs/robot_mini_2x2.md) |
| Modelo 3D del prototipo (Blender) | [`docs/modelo/`](docs/modelo/) |
| **App móvil en React Native (Expo)** · [descargar APK](https://github.com/Ebrahilok/LittleCheeseWorks/releases/latest) | [`app/`](app/) |
| Prototipo anterior en Flutter (con visor 3D) | [`app-flutter/`](app-flutter/) |
| API en ASP.NET Core (.NET 10) con PostgreSQL: login con JWT y CRUD de cuartos y puntos | [`backend/`](backend/) |
| Sketches para comprobar el cableado | [`firmware/prueba_conexiones/`](firmware/prueba_conexiones/) (robot grande) · [`firmware/prueba_mini/`](firmware/prueba_mini/) (robot mini) |

**Estado:** la app de React Native funciona con el robot simulado y con la API (login y puntos guardados). El firmware del robot (navegación y servidor WebSocket) está pendiente; `firmware/` solo contiene el sketch de prueba de conexiones.
