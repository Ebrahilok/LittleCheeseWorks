# Robot Mesero Autónomo con Control Móvil
## Documento de Especificaciones del Proyecto

**Institución:** Universidad Autónoma de Occidente
**Integrantes:** Ali Avila Ebrahim Alejandro; Molina Garcia Jesus Armando; Estavillo Servin Xavier; Ayala Noriega Rey David
**Versión:** 0.1 (borrador)

---

## 1. Introducción

### 1.1 Objetivo
Diseñar y construir un robot móvil de bajo costo que transporte alimentos y bebidas desde una estación base hasta las mesas de un establecimiento, siguiendo rutas fijas y deteniéndose ante obstáculos, controlado mediante una aplicación móvil multiplataforma (Android e iOS).

### 1.2 Alcance
- Robot móvil diferencial con bandeja de carga.
- Navegación por seguidor de línea con detección de obstáculos.
- App móvil para solicitar el envío a una mesa y monitorear el estado.
- Comunicación inalámbrica app ↔ robot.
- Presupuesto máximo: **300 USD**. Plazo: **un semestre (~16 semanas)**.

### 1.3 Fuera de alcance
- Navegación autónoma con mapas (SLAM/LiDAR).
- Reconocimiento de personas o voz.
- Cobro, pagos o integración con sistemas de punto de venta.
- Operación en exteriores o pisos irregulares.

### 1.4 Glosario
| Término | Definición |
|---|---|
| Base | Punto de partida y carga del robot |
| Ruta | Línea en el piso que une la base con cada mesa |
| PID | Controlador proporcional-integral-derivativo |
| BOM | Lista de materiales (Bill of Materials) |

---

## 2. Requisitos

### 2.1 Casos de uso
| ID | Caso de uso | Actor | Descripción |
|---|---|---|---|
| CU-01 | Enviar pedido a mesa | Mesero | Selecciona la mesa en la app y confirma el envío tras cargar la bandeja |
| CU-02 | Llamar al robot | Cliente/Mesero | Solicita que el robot regrese a una mesa o a la base |
| CU-03 | Confirmar entrega | Cliente | Retira el pedido y pulsa "Recibido"; el robot regresa a la base |
| CU-04 | Detener en emergencia | Cualquiera | Detiene el robot desde la app o con el botón físico |

### 2.2 Requisitos funcionales
| ID | Requisito | Criterio de aceptación |
|---|---|---|
| RF-01 | El robot seguirá una línea hasta la mesa seleccionada | Llega a la mesa correcta en ≥ 9 de 10 intentos |
| RF-02 | El robot detectará obstáculos al frente y se detendrá | Se detiene a ≥ 10 cm de un obstáculo a velocidad nominal |
| RF-03 | El robot reanudará la marcha al despejarse el obstáculo | Reanuda en ≤ 3 s tras retirar el obstáculo |
| RF-04 | La app permitirá seleccionar mesa destino (1 a N) | Comando recibido por el robot en ≤ 2 s |
| RF-05 | La app mostrará el estado del robot en tiempo real | Estado actualizado cada ≤ 1 s |
| RF-06 | El robot esperará la confirmación de entrega en la mesa | Permanece detenido hasta confirmación o tiempo límite (60 s) |
| RF-07 | El robot regresará automáticamente a la base | Regresa a la base en ≥ 9 de 10 intentos |
| RF-08 | Parada de emergencia desde la app y botón físico | Motores detenidos en ≤ 500 ms |
| RF-09 | La app notificará fallas (batería baja, obstáculo prolongado, línea perdida) | Notificación en ≤ 3 s |

### 2.3 Requisitos no funcionales
| ID | Requisito | Valor objetivo |
|---|---|---|
| RNF-01 | Carga útil | ≥ 1.5 kg |
| RNF-02 | Velocidad nominal | 0.2–0.4 m/s |
| RNF-03 | Autonomía | ≥ 2 h de uso continuo |
| RNF-04 | Estabilidad | No derramar líquido en aceleración/frenado normales |
| RNF-05 | Costo total | ≤ 300 USD |
| RNF-06 | Compatibilidad app | Android 10+ e iOS 14+ |
| RNF-07 | Seguridad | Sin bordes cortantes; tensión de operación ≤ 12 V |

---

## 3. Hardware y electrónica

### 3.1 Arquitectura general
```
 Batería ─► Regulación 5V/3.3V ─► ESP32 ◄─► Sensores (IR línea, ultrasonido)
    │                               │
    └────► Driver motores ◄─────────┘
                │
          2 motores DC + encoders (opcional)
```

### 3.2 Componentes principales
| Subsistema | Componente sugerido | Función |
|---|---|---|
| Controlador | ESP32 DevKit | Lógica, control y WiFi/BLE |
| Tracción | 2 motores DC con reductora (6–12 V) + rueda loca | Movimiento diferencial |
| Driver | TB6612FNG (o L298N) | Control de motores |
| Línea | Array de 5 sensores IR reflectivos (TCRT5000/QTR) | Detección de la línea |
| Obstáculos | HC-SR04 frontal (opcional: 2 laterales) | Medición de distancia |
| Energía | Batería Li-ion 2S/3S + BMS + convertidor buck | Alimentación |
| Seguridad | Botón de paro de emergencia (corte de motores) | RF-08 |
| Estructura | Chasis acrílico/MDF + bandeja antideslizante | Soporte y carga |
| Indicadores | LED RGB + buzzer | Estado local |

### 3.3 Lista de materiales (BOM) estimada
| Ítem | Cant. | Costo unit. (USD) | Subtotal |
|---|---|---|---|
| ESP32 DevKit | 1 | 10 | 10 |
| Motores DC con reductora | 2 | 12 | 24 |
| Driver TB6612FNG | 1 | 6 | 6 |
| Array sensores IR | 1 | 10 | 10 |
| HC-SR04 | 2 | 3 | 6 |
| Baterías Li-ion 18650 + soporte + BMS | 1 kit | 25 | 25 |
| Convertidor buck | 2 | 4 | 8 |
| Chasis, ruedas, rueda loca, bandeja | 1 | 40 | 40 |
| Botón de emergencia, LEDs, buzzer, cableado | 1 kit | 15 | 15 |
| Cinta para pista, MDF/mesas de prueba | 1 | 25 | 25 |
| Imprevistos (15 %) | — | — | ~25 |
| **Total estimado** | | | **~194** |

Margen disponible respecto al tope de 300 USD: ~106 USD (cargador, repuestos, encoders).

### 3.4 Consideraciones de diseño
- Centro de gravedad bajo; bandeja con borde y superficie antideslizante.
- Aceleración y frenado con rampas suaves para no derramar.
- Filtrado de sensores y diodo de protección contra picos de los motores.

---

## 4. Software y arquitectura

### 4.1 Arquitectura de componentes
```
 App Flutter (Android/iOS)
        │  WiFi (WebSocket o MQTT)
        ▼
 [Broker / punto de acceso local] ◄──► ESP32 (firmware)
                                        ├─ Módulo de comunicación
                                        ├─ Máquina de estados
                                        ├─ Control PID de línea
                                        └─ Lectura de sensores y motores
```
**Decisión recomendada:** ESP32 en modo servidor WebSocket sobre una red WiFi local (o punto de acceso propio). Alternativa: BLE para menor complejidad de red.

### 4.2 Máquina de estados del robot
| Estado | Descripción | Transiciones |
|---|---|---|
| REPOSO | En base, esperando comando | Comando "ir a mesa X" → EN_RUTA |
| EN_RUTA | Sigue la línea hacia la mesa | Obstáculo → OBSTACULO; llega → ESPERANDO; línea perdida → ERROR |
| OBSTACULO | Detenido por objeto | Despejado → estado previo; > 30 s → ERROR |
| ESPERANDO | En mesa, espera confirmación | Confirmación o timeout → REGRESANDO |
| REGRESANDO | Vuelve a la base | Llega → REPOSO; obstáculo → OBSTACULO |
| ERROR / PARO | Falla o emergencia | Reset manual → REPOSO |

Cada mesa se identifica por una marca en la línea (cruce o franja transversal); el firmware cuenta marcas para saber en qué mesa se detiene.

### 4.3 Protocolo de mensajes (JSON)
```json
// App → Robot
{"cmd": "go", "table": 3}
{"cmd": "confirm"}
{"cmd": "stop"}

// Robot → App
{"state": "EN_RUTA", "table": 3, "battery": 78, "obstacle": false}
{"event": "error", "code": "LINE_LOST"}
```

### 4.4 Aplicación móvil (Flutter)
Pantallas: (1) Conexión al robot, (2) Selección de mesa y envío, (3) Estado en tiempo real con botón de paro, (4) Alertas e historial.
Capas: UI → estado (Provider/Riverpod) → servicio de comunicación (WebSocket).

### 4.5 Firmware
- Plataforma: Arduino framework / PlatformIO sobre ESP32.
- Lazo de control a 100 Hz; PID sobre el error de posición de la línea.
- Lectura de ultrasonido a 20 Hz con filtro de mediana.
- *Watchdog* y detención de motores si se pierde la comunicación crítica.

---

## 5. Plan de pruebas

### 5.1 Niveles
1. **Unitarias**: lectura de sensores, PID, parser de mensajes.
2. **Integración**: motores + sensores + comunicación.
3. **Sistema/campo**: recorrido completo en pista con mesas.

### 5.2 Casos de prueba
| ID | Prueba | RF | Resultado esperado |
|---|---|---|---|
| PR-01 | Seguir línea recta y curva | RF-01 | Mantiene la línea sin salirse |
| PR-02 | Obstáculo a 30 cm | RF-02 | Se detiene ≥ 10 cm |
| PR-03 | Retirar obstáculo | RF-03 | Reanuda en ≤ 3 s |
| PR-04 | Enviar a mesa 1–N desde app | RF-04 | Llega a la mesa correcta |
| PR-05 | Latencia de estado | RF-05 | ≤ 1 s |
| PR-06 | Esperar y confirmar entrega | RF-06 | Regresa tras confirmar |
| PR-07 | Regreso a base | RF-07 | Termina en REPOSO en base |
| PR-08 | Paro de emergencia (app y botón) | RF-08 | Motores off ≤ 500 ms |
| PR-09 | Carga de 1.5 kg con vaso de agua | RNF-01/04 | Sin derrame |
| PR-10 | Autonomía | RNF-03 | ≥ 2 h |
| PR-11 | Pérdida de WiFi | RF-08 | Se detiene de forma segura |

### 5.3 Métricas de éxito
Tasa de entrega correcta ≥ 90 %, cero colisiones en 20 recorridos, latencia de comandos ≤ 2 s.

---

## 6. Plan de proyecto

### 6.1 Cronograma (16 semanas)
| Semanas | Actividad | Hito |
|---|---|---|
| 1–2 | Requisitos, diseño, compra de materiales | Documento de specs aprobado |
| 3–5 | Ensamble del chasis y electrónica | Robot se mueve |
| 6–8 | Seguidor de línea con PID y detección de obstáculos | Recorrido básico |
| 9–11 | Comunicación y app Flutter | App controla robot |
| 12–13 | Integración y máquina de estados completa | Entrega de punta a punta |
| 14–15 | Pruebas de campo y ajustes | Informe de pruebas |
| 16 | Documentación final y presentación | Entrega |

### 6.2 Riesgos
| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Derrame por frenado brusco | Media | Alto | Rampas de aceleración, bandeja con borde |
| Pérdida de línea | Media | Medio | Array de 5+ sensores, estado de error |
| WiFi inestable | Media | Alto | Punto de acceso propio, fallback BLE |
| Retraso en compras | Media | Medio | Pedir en semana 1, proveedores locales |
| Presupuesto excedido | Baja | Medio | Margen de 100 USD, componentes genéricos |
| Inexperiencia con Flutter | Media | Medio | Prototipo temprano, tutoriales |

### 6.3 Roles sugeridos
Líder de proyecto, responsable de hardware, responsable de firmware, responsable de app, responsable de pruebas y documentación.

---

## 7. Anexos
- A. Diagrama esquemático (pendiente)
- B. Planos del chasis (pendiente)
- C. Bitácora de pruebas (pendiente)
- D. Referencias
