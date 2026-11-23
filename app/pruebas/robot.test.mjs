// Pruebas de la lógica del robot (sin React Native): protocolo, simulador y reducer.
// Ejecutar con: npm test
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

const { leerMensaje, aCoordenadasPared, aCoordenadasBase, cuartoValido, CUARTO_ESTANDAR, CUARTO_CLASE } =
  await import('@/features/robot/modelo');
const { RobotSimulado } = await import('@/features/robot/RobotSimulado');
const { robotReducer, robotInicial } = await import('@/features/robot/robotReducer');

function crearSimulador(opciones = {}) {
  const mensajes = [];
  const sim = new RobotSimulado(
    { alMensaje: (m) => mensajes.push(m), alCambiarConexion: () => {} },
    CUARTO_ESTANDAR,
    { tickMs: 100, ...opciones },
  );
  const correr = (segundos) => {
    for (let i = 0; i < segundos * 10; i++) sim.paso();
  };
  return { sim, mensajes, correr };
}

describe('protocolo JSON', () => {
  test('lee un mensaje de estado del robot', () => {
    const m = leerMensaje('{"state":"EN_RUTA","x":1.2,"y":0.4,"heading":0.35,"load":true,"calibrated":true,"target":{"x":2.5,"y":1},"battery":78,"obstacle":false}');
    assert.equal(m.tipo, 'status');
    assert.equal(m.status.estado, 'EN_RUTA');
    assert.deepEqual(m.status.destino, { x: 2.5, y: 1 });
    assert.equal(m.status.bateria, 78);
    assert.equal(m.status.conCarga, true);
  });

  test('lee eventos de error y de objetos', () => {
    assert.equal(leerMensaje('{"event":"error","code":"LOW_BATTERY"}').evento.codigo, 'LOW_BATTERY');
    assert.equal(leerMensaje('{"event":"object","id":3,"x":1.8,"y":0.9,"w":0.3,"h":0.3}').objeto.id, 3);
    assert.deepEqual(leerMensaje('{"event":"object_gone","id":3}'), { tipo: 'objetoQuitado', id: 3 });
  });

  test('ignora texto que no es JSON o mensajes desconocidos', () => {
    assert.equal(leerMensaje('hola'), null);
    assert.equal(leerMensaje('[1,2]'), null);
    assert.equal(leerMensaje('{"event":"otro"}'), null);
  });

  test('un estado desconocido se toma como ERROR', () => {
    assert.equal(leerMensaje('{"state":"VOLANDO"}').status.estado, 'ERROR');
  });
});

describe('cuarto', () => {
  test('convierte entre coordenadas de la base y de la pared', () => {
    const p = aCoordenadasPared(CUARTO_ESTANDAR, { x: 1, y: 2 });
    assert.deepEqual(p, { x: 1.5, y: 2.5 });
    assert.deepEqual(aCoordenadasBase(CUARTO_ESTANDAR, p), { x: 1, y: 2 });
  });

  test('valida medidas y que la base quede adentro', () => {
    assert.equal(cuartoValido(CUARTO_CLASE), true);
    assert.equal(cuartoValido({ ancho: 0.5, largo: 2, baseX: 0.1, baseY: 0.1 }), false);
    assert.equal(cuartoValido({ ancho: 2, largo: 2, baseX: 3, baseY: 0.1 }), false);
  });
});

describe('robot simulado', () => {
  test('no se mueve sin calibrar', () => {
    const { sim, correr } = crearSimulador();
    sim.enviar({ cmd: 'goto', x: 2, y: 1 });
    correr(1);
    assert.equal(sim.status.estado, 'ESPERANDO_CARGA');
  });

  test('flujo completo: calibrar, llevar, retirar y regresar a la base', () => {
    const { sim, correr } = crearSimulador();
    sim.enviar({ cmd: 'calibrate' });
    assert.equal(sim.status.estado, 'LISTO');
    sim.enviar({ cmd: 'goto', x: 2, y: 1 });
    assert.equal(sim.status.estado, 'EN_RUTA');
    correr(10);
    assert.equal(sim.status.estado, 'ENTREGANDO');
    assert.ok(Math.hypot(sim.status.x - 2, sim.status.y - 1) <= 0.06);
    sim.enviar({ cmd: 'unload' });
    assert.equal(sim.status.estado, 'REGRESANDO');
    correr(10);
    assert.equal(sim.status.estado, 'ESPERANDO_CARGA');
    assert.equal(sim.status.x, 0);
  });

  test('se detiene ante un objeto y sigue cuando se quita', () => {
    const { sim, mensajes, correr } = crearSimulador();
    sim.enviar({ cmd: 'calibrate' });
    sim.colocarObjeto(1.5, 0);
    sim.enviar({ cmd: 'goto', x: 3, y: 0 });
    correr(5);
    assert.equal(sim.status.estado, 'OBSTACULO');
    assert.ok(mensajes.some((m) => m.tipo === 'objeto'));
    sim.quitarUltimoObjeto();
    correr(0.2);
    assert.equal(sim.status.estado, 'EN_RUTA');
  });

  test('obstáculo prolongado termina en ERROR con alerta', () => {
    const { sim, mensajes, correr } = crearSimulador({ esperaObstaculoMs: 2000 });
    sim.enviar({ cmd: 'calibrate' });
    sim.colocarObjeto(1.5, 0);
    sim.enviar({ cmd: 'goto', x: 3, y: 0 });
    correr(6);
    assert.equal(sim.status.estado, 'ERROR');
    assert.ok(mensajes.some((m) => m.tipo === 'evento' && m.evento.codigo === 'OBSTACLE_TIMEOUT'));
  });

  test('paro de emergencia y reiniciar', () => {
    const { sim, correr } = crearSimulador();
    sim.enviar({ cmd: 'calibrate' });
    sim.enviar({ cmd: 'goto', x: 3, y: 2 });
    correr(1);
    sim.enviar({ cmd: 'stop' });
    assert.equal(sim.status.estado, 'PARO');
    sim.enviar({ cmd: 'goto', x: 1, y: 1 });
    assert.equal(sim.status.estado, 'PARO', 'con falla no acepta destinos');
    sim.enviar({ cmd: 'reset' });
    assert.equal(sim.status.estado, 'LISTO');
  });

  test('el destino se ajusta a los límites del cuarto', () => {
    const { sim } = crearSimulador();
    sim.enviar({ cmd: 'calibrate' });
    sim.enviar({ cmd: 'goto', x: 50, y: -50 });
    assert.deepEqual(sim.status.destino, { x: 5.5, y: -0.5 });
  });
});

describe('reducer del robot', () => {
  test('guarda el recorrido y lo reinicia al volver a la base', () => {
    const status = (x, estado = 'EN_RUTA') => ({ tipo: 'MENSAJE', mensaje: { tipo: 'status', status: { ...robotInicial.status, estado, x, calibrado: true } } });
    let s = robotReducer(robotInicial, status(0));
    s = robotReducer(s, status(0.5));
    s = robotReducer(s, status(0.51)); // menos de 3 cm: no se agrega
    assert.equal(s.recorrido.length, 2);
    s = robotReducer(s, status(0, 'ESPERANDO_CARGA'));
    assert.equal(s.recorrido.length, 0);
  });

  test('un objeto detectado agrega alerta sin leer', () => {
    const s = robotReducer(robotInicial, { tipo: 'MENSAJE', mensaje: { tipo: 'objeto', objeto: { id: 1, x: 1, y: 1, w: 0.3, h: 0.3 } } });
    assert.equal(s.objetos.length, 1);
    assert.equal(s.sinLeer, 1);
    assert.equal(robotReducer(s, { tipo: 'ALERTAS_LEIDAS' }).sinLeer, 0);
  });

  test('perder la conexión del robot real activa la reconexión', () => {
    let s = robotReducer(robotInicial, { tipo: 'INICIAR', simulado: false });
    s = robotReducer(s, { tipo: 'CONEXION', conectado: false });
    assert.equal(s.reconectando, true);
  });
});
