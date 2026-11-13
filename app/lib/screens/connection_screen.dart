import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../models/world.dart';
import '../providers/robot_provider.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  late final _host = TextEditingController(text: ref.read(robotProvider).host);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar. Revisa que el teléfono '
            'esté en la red WiFi del robot y que la IP sea correcta.\n($e)');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _connectReal() {
    final host = _host.text.trim();
    if (host.isEmpty) {
      setState(() => _error = 'Escribe la IP del robot.');
      return;
    }
    _run(() => ref.read(robotProvider.notifier).connectReal(host));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    // Hay un robot elegido (conectado o reintentando).
    final active = session.connected || session.reconnecting;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: session.reconnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3))
                : Icon(
                    session.connected ? Icons.check_circle : Icons.link_off,
                    color: session.connected ? Colors.green : Colors.grey,
                  ),
            title: Text(session.reconnecting
                ? 'Conexión perdida: reconectando…'
                : session.connected
                    ? (session.simulated
                        ? 'Conectado (robot simulado)'
                        : 'Conectado al robot')
                    : 'Sin conexión'),
            subtitle: session.reconnecting
                ? const Text('El robot se detiene solo cuando pierde a la app.')
                : null,
          ),
        ),
        if (session.connected) ...[
          const SizedBox(height: 8),
          _CalibrationCard(session: session),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _host,
          decoration: const InputDecoration(
            labelText: 'IP del robot (ESP32)',
            border: OutlineInputBorder(),
            helperText: 'WebSocket en el puerto 81',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _connectReal,
          icon: const Icon(Icons.wifi),
          label: const Text('Conectar al robot'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _run(ctrl.connectSimulated),
          icon: const Icon(Icons.science),
          label: const Text('Modo simulación'),
        ),
        if (active) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: ctrl.disconnect, child: const Text('Desconectar')),
        ],
        if (_busy) const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        _RoomCard(room: session.room),
      ],
    );
  }
}

/// Paso de inicio: al colocar el objeto en la base el robot fija el origen (0,0).
class _CalibrationCard extends ConsumerWidget {
  const _CalibrationCard({required this.session});
  final RobotSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = session.status;
    final waiting = st.state == RobotState.esperandoCarga;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preparar el robot', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (waiting) ...[
              const Text('1. Deja el robot en el punto de partida (la base).\n'
                  '2. Coloca el objeto a transportar sobre la bandeja.\n'
                  '3. Pulsa Calibrar: ese punto será el origen (0, 0) del mapa.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: ref.read(robotProvider.notifier).calibrate,
                icon: const Icon(Icons.my_location),
                label: const Text('Ya coloqué el objeto: Calibrar'),
              ),
            ] else if (st.calibrated)
              Text('Calibrado. Posición actual: '
                  '(${st.x.toStringAsFixed(2)}, ${st.y.toStringAsFixed(2)}) m. '
                  '${st.hasLoad ? 'Lleva carga.' : 'Sin carga.'} '
                  'Ve a la pestaña Mapa para elegir el destino.')
            else
              const Text('El robot no está calibrado. Pulsa Reiniciar en la pestaña Estado.'),
          ],
        ),
      ),
    );
  }
}

/// Medidas del cuarto y posición de la base dentro de él.
class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});
  final Room room;

  String _m(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          leading: const Icon(Icons.square_foot),
          title: Text('Cuarto: ${_m(room.width)} × ${_m(room.height)} m'),
          subtitle: Text('Base a ${_m(room.baseX)} m de la pared izquierda y '
              '${_m(room.baseY)} m de la pared superior'),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final edited = await showDialog<Room>(
              context: context,
              builder: (_) => _RoomDialog(room: room),
            );
            if (edited != null) ref.read(robotProvider.notifier).setRoom(edited);
          },
        ),
      );
}

class _RoomDialog extends StatefulWidget {
  const _RoomDialog({required this.room});
  final Room room;

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  late final _width = TextEditingController(text: '${widget.room.width}');
  late final _height = TextEditingController(text: '${widget.room.height}');
  late final _baseX = TextEditingController(text: '${widget.room.baseX}');
  late final _baseY = TextEditingController(text: '${widget.room.baseY}');
  String? _error;

  @override
  void dispose() {
    for (final c in [_width, _height, _baseX, _baseY]) {
      c.dispose();
    }
    super.dispose();
  }

  void _preset(Room r) => setState(() {
        _width.text = '${r.width}';
        _height.text = '${r.height}';
        _baseX.text = '${r.baseX}';
        _baseY.text = '${r.baseY}';
        _error = null;
      });

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _save() {
    final w = _num(_width), h = _num(_height), bx = _num(_baseX), by = _num(_baseY);
    if (w == null || h == null || bx == null || by == null) {
      setState(() => _error = 'Escribe las cuatro medidas en metros.');
      return;
    }
    final room = Room.fromSize(width: w, height: h, baseX: bx, baseY: by);
    if (!room.isValid) {
      setState(() => _error = 'Cada lado debe medir entre '
          '${Room.minSide.toStringAsFixed(0)} y ${Room.maxSide.toStringAsFixed(0)} m '
          'y la base debe quedar dentro del cuarto.');
      return;
    }
    Navigator.pop(context, room);
  }

  Widget _field(String label, TextEditingController c, Key key) => TextField(
        key: key,
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: 'm'),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Medidas del cuarto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mide el cuarto y dónde vas a poner la base '
                  '(el punto de partida del robot).'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    key: const Key('presetClase'),
                    label: const Text('Clase: 2 × 2 m'),
                    onPressed: () => _preset(
                        const Room.fromSize(width: 2, height: 2, baseX: 0.25, baseY: 0.25)),
                  ),
                  ActionChip(
                    key: const Key('presetGrande'),
                    label: const Text('Grande: 6 × 4 m'),
                    onPressed: () => _preset(Room.standard),
                  ),
                ],
              ),
              _field('Ancho (izquierda a derecha)', _width, const Key('roomWidth')),
              _field('Largo (arriba a abajo)', _height, const Key('roomHeight')),
              _field('Base: distancia a la pared izquierda', _baseX, const Key('roomBaseX')),
              _field('Base: distancia a la pared superior', _baseY, const Key('roomBaseY')),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      );
}
