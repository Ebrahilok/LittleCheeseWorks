// Prueba de conexiones del robot de carga (ESP32 DevKit V1 de 30 pines).
//
// NO es el firmware del robot: solo sirve para comprobar, pieza por pieza,
// que todo quedó bien cableado. Ver docs/tutorial_conexion.md.
//
// Uso: abre el Monitor Serie a 115200 baudios y escribe una letra:
//   i = buscar la IMU (I2C)        u = leer los 3 ultrasónicos
//   e = ver los encoders           b = voltaje de batería / paro de emergencia
//   l = probar LED y buzzer        m = probar motores (¡ruedas al aire!)
//   w = crear la red WiFi del robot
//
// Solo usa las librerías que ya trae el núcleo "esp32" de Arduino.

#include <WiFi.h>
#include <Wire.h>

// ---- Pines (deben coincidir con docs/tutorial_conexion.md) -----------------
const int PIN_SDA = 21, PIN_SCL = 22;                 // IMU MPU6050
const int PIN_PWMA = 25, PIN_AIN1 = 26, PIN_AIN2 = 27; // Motor izquierdo
const int PIN_PWMB = 13, PIN_BIN1 = 32, PIN_BIN2 = 33; // Motor derecho
const int PIN_ENC_IZQ_A = 18, PIN_ENC_IZQ_B = 19;
const int PIN_ENC_DER_A = 16, PIN_ENC_DER_B = 17;
const int PIN_TRIG_FRENTE = 23, PIN_ECHO_FRENTE = 36;
const int PIN_TRIG_IZQ = 15, PIN_ECHO_IZQ = 39;
const int PIN_TRIG_DER = 5, PIN_ECHO_DER = 34;
const int PIN_VM = 35;                                // Voltaje de motores (divisor)
const int PIN_BUZZER = 4, PIN_LED_ROJO = 14, PIN_LED_VERDE = 2;

// Divisor de voltaje de PIN_VM: 10 kΩ arriba, 2.2 kΩ abajo.
const float DIVISOR = (10000.0 + 2200.0) / 2200.0;

// 11 pulsos por vuelta del motor x reducción 45:1 x 4 flancos (cuadratura).
const float CUENTAS_POR_VUELTA = 11.0 * 45.0 * 4.0;

volatile long cuentasIzq = 0, cuentasDer = 0;

void IRAM_ATTR isrIzqA() { cuentasIzq += (digitalRead(PIN_ENC_IZQ_A) == digitalRead(PIN_ENC_IZQ_B)) ? -1 : 1; }
void IRAM_ATTR isrIzqB() { cuentasIzq += (digitalRead(PIN_ENC_IZQ_A) == digitalRead(PIN_ENC_IZQ_B)) ? 1 : -1; }
void IRAM_ATTR isrDerA() { cuentasDer += (digitalRead(PIN_ENC_DER_A) == digitalRead(PIN_ENC_DER_B)) ? -1 : 1; }
void IRAM_ATTR isrDerB() { cuentasDer += (digitalRead(PIN_ENC_DER_A) == digitalRead(PIN_ENC_DER_B)) ? 1 : -1; }

void motor(int pinPwm, int pinIn1, int pinIn2, int potencia) { // potencia: -255..255
  digitalWrite(pinIn1, potencia > 0);
  digitalWrite(pinIn2, potencia < 0);
  analogWrite(pinPwm, abs(potencia));
}

void pararMotores() {
  motor(PIN_PWMA, PIN_AIN1, PIN_AIN2, 0);
  motor(PIN_PWMB, PIN_BIN1, PIN_BIN2, 0);
}

float voltajeMotores() {
  long mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(PIN_VM);
  return (mv / 16.0 / 1000.0) * DIVISOR;
}

float distanciaCm(int trig, int echo) {
  digitalWrite(trig, LOW);
  delayMicroseconds(3);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  unsigned long us = pulseIn(echo, HIGH, 30000); // 30 ms = unos 5 m
  return us == 0 ? -1 : us / 58.0;
}

void probarImu() {
  Serial.println("Buscando dispositivos I2C...");
  int encontrados = 0;
  for (int dir = 1; dir < 127; dir++) {
    Wire.beginTransmission(dir);
    if (Wire.endTransmission() == 0) {
      Serial.printf("  Dispositivo en 0x%02X%s\n", dir, (dir == 0x68 || dir == 0x69) ? "  <- MPU6050" : "");
      encontrados++;
    }
  }
  if (encontrados == 0) Serial.println("  Nada. Revisa SDA=21, SCL=22, VCC=3V3 y GND.");
}

void probarUltrasonicos() {
  for (int i = 0; i < 10; i++) {
    float f = distanciaCm(PIN_TRIG_FRENTE, PIN_ECHO_FRENTE);
    delay(30); // deja que se apague el eco antes de disparar el siguiente
    float iz = distanciaCm(PIN_TRIG_IZQ, PIN_ECHO_IZQ);
    delay(30);
    float de = distanciaCm(PIN_TRIG_DER, PIN_ECHO_DER);
    Serial.printf("  frente %6.1f cm | izquierda %6.1f cm | derecha %6.1f cm   (-1 = sin eco)\n", f, iz, de);
    delay(300);
  }
}

void probarEncoders() {
  Serial.println("Gira cada rueda con la mano hacia ADELANTE: su cuenta debe SUBIR.");
  Serial.println("Si baja, intercambia los cables amarillo y verde de ese motor.");
  for (int i = 0; i < 20; i++) {
    long iz = cuentasIzq, de = cuentasDer;
    Serial.printf("  izq %7ld (%.2f vueltas) | der %7ld (%.2f vueltas)\n",
                  iz, iz / CUENTAS_POR_VUELTA, de, de / CUENTAS_POR_VUELTA);
    delay(500);
  }
}

void probarBateria() {
  float v = voltajeMotores();
  Serial.printf("  Voltaje en VM: %.2f V\n", v);
  if (v < 2.0) Serial.println("  -> Paro de emergencia PRESIONADO (o falta el divisor / la bateria).");
  else if (v < 9.6) Serial.println("  -> Bateria BAJA: cargala antes de seguir.");
  else Serial.println("  -> Correcto (3S llena = 12.6 V, vacia = 9.0 V).");
}

void probarLedBuzzer() {
  Serial.println("  LED rojo, LED verde, buzzer...");
  digitalWrite(PIN_LED_ROJO, HIGH); delay(600); digitalWrite(PIN_LED_ROJO, LOW);
  digitalWrite(PIN_LED_VERDE, HIGH); delay(600); digitalWrite(PIN_LED_VERDE, LOW);
  digitalWrite(PIN_BUZZER, HIGH); delay(200); digitalWrite(PIN_BUZZER, LOW);
}

// Mueve un motor 1.5 s y avisa si el encoder no contó o contó al revés.
void probarUnMotor(const char* nombre, int pwm, int in1, int in2, volatile long* cuentas) {
  long antes = *cuentas;
  Serial.printf("  %s hacia ADELANTE...\n", nombre);
  motor(pwm, in1, in2, 110);
  delay(1500);
  motor(pwm, in1, in2, 0);
  delay(300);
  long d = *cuentas - antes;
  if (labs(d) < 50) Serial.println("    El encoder no conto: revisa azul=3V3, negro=GND, amarillo/verde.");
  else if (d < 0) Serial.println("    El encoder cuenta al reves: intercambia amarillo y verde.");
  else Serial.printf("    Encoder correcto (%ld cuentas). Si la rueda giro hacia ATRAS, intercambia rojo y blanco.\n", d);
}

void probarMotores() {
  if (voltajeMotores() < 2.0) {
    Serial.println("  Sin voltaje en VM: suelta el paro de emergencia y enciende el interruptor.");
    return;
  }
  Serial.println("  LEVANTA EL ROBOT: las ruedas no deben tocar el piso. Empieza en 3 s...");
  delay(3000);
  probarUnMotor("Motor IZQUIERDO", PIN_PWMA, PIN_AIN1, PIN_AIN2, &cuentasIzq);
  probarUnMotor("Motor DERECHO", PIN_PWMB, PIN_BIN1, PIN_BIN2, &cuentasDer);
  pararMotores();
}

void probarWifi() {
  WiFi.mode(WIFI_AP);
  bool ok = WiFi.softAP("RobotCarga", "robot1234");
  Serial.printf("  Red \"RobotCarga\" (clave robot1234): %s. IP del robot: %s\n",
                ok ? "creada" : "FALLO", WiFi.softAPIP().toString().c_str());
  Serial.println("  Conecta el telefono a esa red para comprobar que aparece.");
}

void menu() {
  Serial.println("\n== Prueba de conexiones ==  i=IMU  u=ultrasonicos  e=encoders  b=bateria/paro  l=LED/buzzer  m=motores  w=WiFi");
}

void setup() {
  Serial.begin(115200);
  for (int p : {PIN_AIN1, PIN_AIN2, PIN_BIN1, PIN_BIN2, PIN_PWMA, PIN_PWMB,
                PIN_TRIG_FRENTE, PIN_TRIG_IZQ, PIN_TRIG_DER,
                PIN_BUZZER, PIN_LED_ROJO, PIN_LED_VERDE}) {
    pinMode(p, OUTPUT);
    digitalWrite(p, LOW);
  }
  pararMotores();
  for (int p : {PIN_ECHO_FRENTE, PIN_ECHO_IZQ, PIN_ECHO_DER}) pinMode(p, INPUT);
  for (int p : {PIN_ENC_IZQ_A, PIN_ENC_IZQ_B, PIN_ENC_DER_A, PIN_ENC_DER_B}) pinMode(p, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_IZQ_A), isrIzqA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_IZQ_B), isrIzqB, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_DER_A), isrDerA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_DER_B), isrDerB, CHANGE);
  Wire.begin(PIN_SDA, PIN_SCL);
  delay(300);
  menu();
}

void loop() {
  if (!Serial.available()) return;
  char c = Serial.read();
  switch (c) {
    case 'i': probarImu(); break;
    case 'u': probarUltrasonicos(); break;
    case 'e': probarEncoders(); break;
    case 'b': probarBateria(); break;
    case 'l': probarLedBuzzer(); break;
    case 'm': probarMotores(); break;
    case 'w': probarWifi(); break;
    case '\n': case '\r': return;
    default: Serial.printf("Letra desconocida: %c\n", c);
  }
  menu();
}
