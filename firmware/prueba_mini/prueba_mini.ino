// Prueba de conexiones del ROBOT MINI (cuarto de 2 x 2 m).
// Ver docs/robot_mini_2x2.md. NO es el firmware del robot.
//
// Monitor Serie a 115200 baudios. Escribe una letra:
//   u = ultrasonico     b = voltaje de las pilas   l = LED
//   m = motores (RUEDAS AL AIRE)    r = sensores de rueda    w = WiFi
//
// Sin compilar ni probar en hardware: se escribio sin Arduino instalado.

#include <WiFi.h>

// ---- Pines (iguales a los del robot grande) --------------------------------
const int PIN_PWMA = 25, PIN_AIN1 = 26, PIN_AIN2 = 27;  // Motor izquierdo
const int PIN_PWMB = 13, PIN_BIN1 = 32, PIN_BIN2 = 33;  // Motor derecho
const int PIN_RUEDA_IZQ = 18, PIN_RUEDA_DER = 16;       // Sensores F249 (una senal)
const int PIN_TRIG = 23, PIN_ECHO = 36;                 // HC-SR04P frontal
const int PIN_PILAS = 35;                               // Divisor 10k / 10k
const int PIN_LED_ROJO = 14, PIN_LED_VERDE = 2;

const float DIVISOR = 2.0;           // (10k + 10k) / 10k
const float PILAS_BAJAS = 4.8;       // por debajo, el ESP32 puede reiniciarse

volatile long pulsosIzq = 0, pulsosDer = 0;
void IRAM_ATTR isrIzq() { pulsosIzq++; }
void IRAM_ATTR isrDer() { pulsosDer++; }

void motor(int pinPwm, int pinIn1, int pinIn2, int potencia) {  // -255..255
  digitalWrite(pinIn1, potencia > 0);
  digitalWrite(pinIn2, potencia < 0);
  analogWrite(pinPwm, abs(potencia));
}

void pararMotores() {
  motor(PIN_PWMA, PIN_AIN1, PIN_AIN2, 0);
  motor(PIN_PWMB, PIN_BIN1, PIN_BIN2, 0);
}

float voltajePilas() {
  long mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(PIN_PILAS);
  return (mv / 16.0 / 1000.0) * DIVISOR;
}

float distanciaCm() {
  digitalWrite(PIN_TRIG, LOW);
  delayMicroseconds(3);
  digitalWrite(PIN_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);
  unsigned long us = pulseIn(PIN_ECHO, HIGH, 30000);
  return us == 0 ? -1 : us / 58.0;
}

void probarUltrasonico() {
  for (int i = 0; i < 12; i++) {
    Serial.printf("  frente %6.1f cm   (-1 = sin eco)\n", distanciaCm());
    delay(300);
  }
}

void probarPilas() {
  float v = voltajePilas();
  Serial.printf("  Pilas: %.2f V\n", v);
  if (v < 1.0) Serial.println("  -> Casi 0 V: revisa el divisor, el interruptor y que haya pilas.");
  else if (v < PILAS_BAJAS) Serial.println("  -> BAJAS: cambia las pilas antes de seguir.");
  else Serial.println("  -> Correcto (4 pilas alcalinas nuevas: unos 6.0 a 6.4 V).");
}

void probarLed() {
  digitalWrite(PIN_LED_ROJO, HIGH); delay(600); digitalWrite(PIN_LED_ROJO, LOW);
  digitalWrite(PIN_LED_VERDE, HIGH); delay(600); digitalWrite(PIN_LED_VERDE, LOW);
}

void probarRuedas() {
  Serial.println("  Gira cada rueda a mano: su cuenta debe subir. (cuenta los pulsos de UNA vuelta)");
  for (int i = 0; i < 20; i++) {
    Serial.printf("  izq %5ld | der %5ld\n", pulsosIzq, pulsosDer);
    delay(500);
  }
}

void probarUnMotor(const char* nombre, int pwm, int in1, int in2, volatile long* pulsos) {
  long antes = *pulsos;
  Serial.printf("  %s hacia ADELANTE...\n", nombre);
  motor(pwm, in1, in2, 150);
  delay(1500);
  motor(pwm, in1, in2, 0);
  delay(300);
  long d = *pulsos - antes;
  if (d < 5) Serial.println("    Casi sin pulsos: revisa el sensor (VCC, GND, OUT) y que el disco pase por la ranura.");
  else Serial.printf("    Sensor correcto (%ld pulsos). Si la rueda giro hacia ATRAS, intercambia los dos cables del motor.\n", d);
}

void probarMotores() {
  if (voltajePilas() < PILAS_BAJAS) {
    Serial.println("  Pilas bajas o apagadas: enciende el interruptor / cambia las pilas.");
    return;
  }
  Serial.println("  LEVANTA EL ROBOT: las ruedas no deben tocar la mesa. Empieza en 3 s...");
  delay(3000);
  probarUnMotor("Motor IZQUIERDO", PIN_PWMA, PIN_AIN1, PIN_AIN2, &pulsosIzq);
  probarUnMotor("Motor DERECHO", PIN_PWMB, PIN_BIN1, PIN_BIN2, &pulsosDer);
  pararMotores();
}

void probarWifi() {
  WiFi.mode(WIFI_AP);
  bool ok = WiFi.softAP("RobotCarga", "robot1234");
  Serial.printf("  Red \"RobotCarga\" (clave robot1234): %s. IP: %s\n",
                ok ? "creada" : "FALLO", WiFi.softAPIP().toString().c_str());
}

void menu() {
  Serial.println("\n== Robot mini ==  u=ultrasonico  b=pilas  l=LED  m=motores  r=ruedas  w=WiFi");
}

void setup() {
  Serial.begin(115200);
  for (int p : {PIN_AIN1, PIN_AIN2, PIN_BIN1, PIN_BIN2, PIN_PWMA, PIN_PWMB,
                PIN_TRIG, PIN_LED_ROJO, PIN_LED_VERDE}) {
    pinMode(p, OUTPUT);
    digitalWrite(p, LOW);
  }
  pararMotores();
  pinMode(PIN_ECHO, INPUT);
  pinMode(PIN_RUEDA_IZQ, INPUT);
  pinMode(PIN_RUEDA_DER, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_RUEDA_IZQ), isrIzq, RISING);
  attachInterrupt(digitalPinToInterrupt(PIN_RUEDA_DER), isrDer, RISING);
  delay(300);
  menu();
}

void loop() {
  if (!Serial.available()) return;
  char c = Serial.read();
  switch (c) {
    case 'u': probarUltrasonico(); break;
    case 'b': probarPilas(); break;
    case 'l': probarLed(); break;
    case 'm': probarMotores(); break;
    case 'r': probarRuedas(); break;
    case 'w': probarWifi(); break;
    case '\n': case '\r': return;
    default: Serial.printf("Letra desconocida: %c\n", c);
  }
  menu();
}
