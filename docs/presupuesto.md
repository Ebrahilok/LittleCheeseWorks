# Presupuesto y enlaces de compra

**Fecha de los precios:** 11 de noviembre de 2026 · **Moneda:** pesos mexicanos (MXN) · **Equipo:** 4 personas

## Resumen

Hay tres opciones. La **Opción 1 (robot mini para 2 × 2 m)** es la recomendada para la clase; las otras dos son el robot grande completo.

| | **Opción 1: robot mini 2 × 2 m** | Opción 2 (Plan A): robot grande, el más barato | Opción 3 (Plan B): robot grande, todo nacional |
|---|---|---|---|
| Cuarto | 2 × 2 m | 6 × 4 m | 6 × 4 m |
| Dónde se compra | Todo en UNIT Electronics | UNIT + kit de AliExpress + compra local | UNIT + Mercado Libre + compra local |
| Tiempo de entrega | Días | 2 a 4 semanas lo de AliExpress | Días |
| Subtotal | $782 (piezas $632 + envío $150) | $1,749 | $2,156–2,316 |
| Imprevistos (10 %) | $78 | $175 | $216–232 |
| **Total** | **$860** | **$1,924** | **$2,372–2,548** |
| **Por persona (÷ 4)** | **$215** | **$481** | **$593–637** |
| Cumple carga 1.5 kg, 2 h y 10 cm | No (ver abajo) | Sí | Sí |
| Detalle y enlaces | [`robot_mini_2x2.md`](robot_mini_2x2.md) | Más abajo | Más abajo |

El tope del proyecto es de 300 USD (RNF-05). Con un tipo de cambio de entre 17 y 20 pesos por dólar, la Opción 1 equivale a unos 43–51 USD, la Opción 2 a unos 96–113 USD y la Opción 3 a unos 119–150 USD.

### Qué se pierde con el robot mini

El robot mini ahorra unos $1,060 en total (unos $266 por persona) respecto a la Opción 2, pero **no cumple tres requisitos** de [`especificaciones.md`](especificaciones.md):

| Requisito | Robot grande | Robot mini |
|---|---|---|
| RNF-01 Carga | 1.5 kg | Unos 200–300 g (no probado) |
| RNF-03 Autonomía | ≥ 2 h | Una o dos horas con pilas AA |
| RNF-08 Precisión | ≤ 10 cm | Sin garantía: esperar 5 a 10 cm en 2 m |

Además, el paro físico es el interruptor del portapilas, no un botón de hongo, y hay un solo ultrasónico y ningún IMU. Antes de comprar el mini hay que confirmar dos datos que la ficha de UNIT no da (voltaje de los motores del kit y si tienen eje doble para los discos encoder): están explicados en la sección 3 de `robot_mini_2x2.md`.

**Recomendación:** si la clase pide demostrar el flujo (calibrar, llevar un objeto ligero a un punto, detenerse ante un obstáculo, regresar), comprar la **Opción 1**. Si exige los requisitos de carga, autonomía y precisión, comprar la **Opción 2** pidiéndola en la semana 1 del cronograma; pasa a la Opción 3 solo si AliExpress no llega a tiempo, comprando únicamente los renglones de tracción.

### Qué tan confiables son estos precios

| Fuente | Cómo se obtuvo | Confianza |
|---|---|---|
| **UNIT Electronics** (tienda mexicana, envía a todo el país) | Precio y existencia leídos del catálogo de la tienda el día de la fecha | Alta: todos los renglones marcados UNIT estaban **en existencia** |
| **AliExpress** | Precio visto en la página de búsqueda ese día | Media: cambia con ofertas, variante elegida e impuestos de importación |
| **Mercado Libre y Amazon México** | **No se pudieron consultar** (bloquean la lectura automática) | Los enlaces son búsquedas y los montos son **estimados**: confirmar antes de comprar |
| Ferretería / papelería local | Estimado | Baja: depende de la ciudad |

El **envío de UNIT** ($150) es un estimado que no se pudo confirmar; el costo real aparece en el carrito (puede ser gratis pasado un mínimo de compra).

---

## Opción 2 (Plan A): robot grande, lista de compras

### 1. UNIT Electronics (precios verificados, en existencia)

| # | Pieza | Cant. | Unitario | Subtotal | Enlace |
|---|---|---|---|---|---|
| 1 | ESP32 DevKit V1 30 pines, versión USB-C | 1 | $133 | $133 | [uelectronics.com](https://uelectronics.com/producto/esp32-devkit-v1-30-pines-usb-c-microusb/) |
| 2 | Driver doble puente H TB6612FNG | 1 | $54 | $54 | [uelectronics.com](https://uelectronics.com/producto/doble-puente-h-tb6612fng/) |
| 3 | IMU MPU6050 | 1 | $87 | $87 | [uelectronics.com](https://uelectronics.com/producto/imu-mpu6050-6-grados-de-libertad/) |
| 4 | Sensor ultrasónico **HC-SR04P** (3–5 V) | 3 | $32 | $96 | [uelectronics.com](https://uelectronics.com/producto/hc-sr04p-sensor-ultrasonico-3-5v/) |
| 5 | Soporte para sensor HC-SR04 | 3 | $12 | $36 | [uelectronics.com](https://uelectronics.com/producto/soporte-para-sensor-ultrasonico-hc-sr04/) |
| 6 | Batería Li-ion 11.1 V 3S1P 2200 mAh con BMS | 1 | $261 | $261 | [uelectronics.com](https://uelectronics.com/producto/bateria-18650-de-11-1v-3s1p-2200mah-3s2p-4400mah/) |
| 7 | Eliminador/cargador 12.6 V 1 A con plug | 1 | $48 | $48 | [uelectronics.com](https://uelectronics.com/producto/fuente-de-alimentacion-1a-8-4v-12-6v-con-plug/) |
| 8 | Convertidor buck LM2596 step-down 3 A | 1 | $36 | $36 | [uelectronics.com](https://uelectronics.com/producto/modulo-regulador-ajustable-lm2596-dc-dc-step-down-3a-1-25-30v/) |
| 9 | Rueda loca de nylon 25 mm | 1 | $20 | $20 | [uelectronics.com](https://uelectronics.com/producto/rueda-loca-nylon-con-25mm-para-carrito/) |
| 10 | Buzzer activo 5 V | 1 | $11 | $11 | [uelectronics.com](https://uelectronics.com/producto/buzzer-activo-3v-5v-12v-zumbador/) |
| 11 | LED bicolor rojo-verde de cátodo común (1 de repuesto) | 2 | $3 | $6 | [uelectronics.com](https://uelectronics.com/producto/led-bicolor-catodo-comun/) |
| 12 | Transistor 2N2222 TO-92 (1 de repuesto) | 2 | $1 | $2 | [uelectronics.com](https://uelectronics.com/producto/2n2222-transistor-bjt-npn-40v-to-92/) |
| 13 | Protoboard de 400 puntos | 1 | $18 | $18 | [uelectronics.com](https://uelectronics.com/producto/protoboard-de-400pts-y-830pts-blanco-o-transparente/) |
| 14 | Placa perforada 48 × 133 mm (para soldar la versión final) | 1 | $16 | $16 | [uelectronics.com](https://uelectronics.com/producto/placa-perforada-tipo-protoboard-48-x-133-mm/) |
| 15 | Cables dupont: 2 paquetes de 30 cm macho-hembra y 1 hembra-hembra | 3 | $26 / $17 | $69 | [30 cm](https://uelectronics.com/producto/cables-dupont-extra-largos-30cm-hh-mh-mm/) · [H-H](https://uelectronics.com/producto/cable-dupont-hembra-hembra/) |
| 16 | Interruptor basculante KCD1 cableado | 1 | $25 | $25 | [uelectronics.com](https://uelectronics.com/producto/interruptor-basculante-kcd1-cableado/) |
| 17 | Jack DC hembra de panel (para enchufar la batería) | 1 | $14 | $14 | [uelectronics.com](https://uelectronics.com/producto/dc-017-conector-jack-dc-hembra-para-montaje-en-panel/) |
| 18 | Bornera KF301 de 2 pines | 4 | $5 | $20 | [uelectronics.com](https://uelectronics.com/producto/bornera-kf301-de-2-3-4-pines-5mm-paso-b/) |
| 19 | Separador de latón M3: 4 de 50 mm y 4 de 40 mm | 8 | $12 / $10 | $88 | [uelectronics.com](https://uelectronics.com/producto/separador-de-laton-m3/) |
| 20 | Resistencias 1/4 W: 10 kΩ, 2.2 kΩ, 1 kΩ, 220 Ω × 2 y repuestos | ~10 | ~$1 | $10 *(estimado)* | [buscar en UNIT](https://uelectronics.com/?s=resistencia+1%2F4&post_type=product) |
| | **Subtotal UNIT** | | | **$1,050** | |

Los precios 15 y 18 usan la variante más cara del rango publicado. El 20 es estimado: en UNIT las resistencias sueltas rondan $0.50.

### 2. AliExpress (precio visto el día de la fecha)

| # | Pieza | Cant. | Unitario | Subtotal | Enlace |
|---|---|---|---|---|---|
| 21 | Kit de tracción: motorreductor con **encoder** + soporte de montaje + llanta de 65 mm | 2 | $118.90 | $237.80 | [aliexpress.com](https://es.aliexpress.com/item/1005009495135021.html) |
| 22 | Botón de paro de emergencia tipo hongo, 22 mm, contacto 1NC (XB2-BS542) | 1 | $11.38 | $11.38 | [aliexpress.com](https://es.aliexpress.com/item/32843542465.html) |
| | **Subtotal AliExpress** | | | **$249** | |

Al pedir el kit de tracción (renglón 21):

- Elige la variante de **12 V** y entre **100 y 150 RPM**. Con llanta de 65 mm, 140 RPM en vacío dan unos 0.5 m/s y, con carga, quedan dentro del rango de RNF-02 (0.2–0.5 m/s). Una variante más rápida tiene menos fuerza para 1.5 kg de carga.
- Antes de pagar, confirma en la ficha que **incluye el cople** entre el eje y la llanta, y que el eje es de 4 mm.
- El título de la publicación no dice las RPM ni los pulsos del encoder. Al recibirlo, mide las cuentas por vuelta con la prueba `e` del tutorial y confirma el orden de colores del cable.
- Muchos productos de AliExpress muestran $20.67 con la etiqueta "nuevo comprador": es una oferta de bienvenida, no el precio normal. Los dos precios de arriba no llevan esa etiqueta.

### 3. Compra local (estimado)

| # | Pieza | Estimado |
|---|---|---|
| 23 | MDF: placa de chasis de 5–6 mm, placa de electrónica y bandeja de 3 mm (28 × 22, 28 × 22 y 22 × 22 cm) | $120 |
| 24 | Tapete antideslizante para la bandeja | $40 |
| 25 | Tornillos y tuercas M3 (unos 30) | $40 |
| 26 | Cable calibre 22 AWG rojo y negro, 3 m | $30 |
| 27 | Portafusible en línea con fusible de 5 A | $25 |
| 28 | Capacitor electrolítico 470 µF / 25 V | $5 |
| 29 | Cinchos, cinta doble cara y termocontráctil | $40 |
| | **Subtotal local** | **$300** |

### 4. Total del Plan A

| Concepto | Monto |
|---|---|
| UNIT Electronics | $1,050 |
| AliExpress | $249 |
| Compra local (estimado) | $300 |
| Envío de UNIT (estimado) | $150 |
| **Subtotal** | **$1,749** |
| Imprevistos (10 %) | $175 |
| **Total** | **$1,924** |
| **Por persona (÷ 4)** | **$481** |

---

## Opción 3 (Plan B): robot grande, todo nacional

Igual que el Plan A, pero se cambian los renglones 21 y 22:

| # | Pieza | Cant. | Subtotal | Dónde |
|---|---|---|---|---|
| 21a | Motor GM25-370 12 V **140 RPM** con encoder (verificado, en existencia) | 2 × $213 | $426 | [uelectronics.com](https://uelectronics.com/producto/gm-25-370-motor-con-encoder-12v-dc-140rpm-330rpm/) |
| 21b | Soporte metálico en L para motor de 25 mm | 2 | $40–70 *(estimado)* | [Mercado Libre](https://listado.mercadolibre.com.mx/soporte-motor-25mm-ga25) · [AliExpress, $29.50 c/u](https://es.aliexpress.com/item/1005006039521658.html) |
| 21c | Cople hexagonal de 12 mm para eje de 4 mm | 2 | $40–80 *(estimado)* | [Mercado Libre](https://listado.mercadolibre.com.mx/cople-hexagonal-12mm-eje-4mm) |
| 21d | Llanta de 65 mm con hueco hexagonal de 12 mm | 2 | $80–140 *(estimado)* | [Mercado Libre](https://listado.mercadolibre.com.mx/llanta-65mm-cople-hexagonal-12mm) · [AliExpress, 4 piezas por $112.77](https://es.aliexpress.com/item/1005008364771614.html) |
| 22 | Botón de paro de emergencia tipo hongo, 22 mm, NC (XB2-BS542 o similar) | 1 | $70–100 *(estimado)* | [Mercado Libre](https://listado.mercadolibre.com.mx/boton-paro-de-emergencia-hongo-22mm) · [Amazon](https://www.amazon.com.mx/s?k=boton+paro+de+emergencia+22mm) |

| Concepto | Monto |
|---|---|
| UNIT Electronics (renglones 1–20) | $1,050 |
| Motores de UNIT | $426 |
| Soportes, coples, llantas y paro (estimado) | $230–390 |
| Compra local (estimado) | $300 |
| Envío de UNIT (estimado) | $150 |
| **Subtotal** | **$2,156–2,316** |
| Imprevistos (10 %) | $216–232 |
| **Total** | **$2,372–2,548** |
| **Por persona (÷ 4)** | **$593–637** |

El motor de UNIT es el que usa el tutorial de conexión: 45:1, 11 pulsos por vuelta de motor, corriente nominal ≤ 0.8 A y de bloqueo ≤ 2 A, eje "D" de 4 mm. Se elige el de **140 RPM** y no el de 330 RPM ($181): el rápido pide hasta 3 A bloqueado, más de lo que el TB6612FNG entrega de forma continua.

Otras opciones de motor, comparadas (precios de búsquedas públicas, sin confirmar en el carrito):

| Opción | 2 motores | Nota |
|---|---|---|
| Kit de AliExpress (motor + soporte + llanta) | ~$238 | El más barato; 2 a 4 semanas |
| UNIT Electronics, motor 140 RPM | $426 (2 × $213) | Precio verificado; sin soporte, cople ni llanta |
| Amazon México, mismo motor de UNIT | ~$490 | Más caro que la tienda oficial: evitarlo |
| Mercado Libre, motores genéricos de 25 mm con encoder | ~$350–450 | Calidad variable: revisar opiniones, eje de 4 mm tipo "D" y encoder Hall |

UNIT no vende soporte ni cople para este motor. Su "Llanta de goma 65 mm con accesorios" trae un buje para motores de eje más grueso (series JGY370 y JGB37) y estaba agotada.

---

## Por qué estas piezas y no otras más baratas

| Decisión | Razón |
|---|---|
| Motor de 25 mm con encoder Hall, no el motor amarillo "TT" | El TT cuesta la cuarta parte, pero tiene juego en los engranes y no trae encoder de cuadratura. Sin encoder confiable el robot no cumple el error de 10 cm (RF-02, RNF-08) |
| TB6612FNG, no L298N | El L298N pierde unos 2 V en calor y es más grande. El TB6612FNG cuesta casi lo mismo y aguanta el motor elegido |
| HC-SR04**P**, no HC-SR04 | Cuestan igual ($32). La versión P trabaja a 3.3 V, así que su señal entra directo al ESP32 sin divisores que se puedan armar mal |
| Paquete de batería armado con BMS, no celdas sueltas | Trae protección de sobrecarga, sobredescarga y corto. Armar un paquete con celdas sueltas exige soldadura de punto y es donde más fallan los proyectos |
| Un solo buck (la v0.2 pedía 2) | Uno de 3 A sobra para el ESP32 y los sensores (menos de 0.5 A) |
| LED bicolor, no RGB | El ESP32 ya no tiene pines seguros libres para el azul. Rojo, verde y amarillo alcanzan para indicar el estado |
| Versión USB-C del ESP32 | Es la más barata ($133 contra $146). Usa el chip CH340: hay que instalar ese controlador |

### Autonomía esperada

Consumo estimado en marcha: unos 0.6 A en los motores más 0.15 A de electrónica, es decir 0.75 A a 11.1 V. Con 2200 mAh salen unas **2.9 h** teóricas y cerca de 2 h reales dejando margen, justo lo que pide RNF-03. **Es un cálculo, no una medición**: se confirma con la prueba PR-13. Si no alcanza, el paquete 3S2P de 4400 mAh de la misma página cuesta $476 (+$215).

### Lo que puede subir el costo

- Envío e impuestos de importación de AliExpress.
- Que el cargador y la batería no tengan plugs compatibles: el cargador es de 5.5 × 2.5 mm y la ficha de la batería solo dice "5.5 mm". Un adaptador o jack extra cuesta unos $15–20.
- Herramienta que el equipo no tenga (multímetro, cautín).

---

## Reparto de la Opción 2 (Plan A) entre los cuatro integrantes

Reparto parejo del Plan A: **$481 por persona**. Para no depender de transferencias entre todos, cada quien puede hacerse cargo de un pedido:

| Integrante | Compra | Paga | Ajuste para quedar en $481 |
|---|---|---|---|
| 1 | Pedido de UNIT, primera mitad (renglones 1–6: $667) | $667 | Recibe $186 |
| 2 | Resto de UNIT (renglones 7–20: $383) + envío ($150) | $533 | Recibe $52 |
| 3 | AliExpress ($249) + fondo de imprevistos ($175) | $424 | Aporta $57 |
| 4 | Compra local ($300) | $300 | Aporta $181 |
| | **Total** | **$1,924** | |

Conviene hacer **un solo pedido a UNIT** para pagar un envío; la división de arriba solo indica quién pone el dinero. El fondo de imprevistos se devuelve en partes iguales si no se usa.

---

## Reparto de la Opción 1 (robot mini)

Total $860 entre 4: **$215 por persona**. Como todo sale de UNIT, conviene **un solo pedido** (un solo envío):

| Concepto | Monto |
|---|---|
| Pedido a UNIT (piezas $632 + envío estimado $150) | $782 |
| Fondo de imprevistos (10 %) | $78 |
| **Total que se reúne** | **$860** |

Cada integrante aporta $215. Quien hace el pedido a UNIT paga los $782 y guarda los $78 restantes como fondo de imprevistos (pilas de repuesto, un cable que falle, un capacitor); si no se usan, se devuelven en partes iguales. Si el envío real resulta menor o gratis, también se devuelve la diferencia.
