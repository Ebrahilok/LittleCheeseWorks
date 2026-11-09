import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../providers/robot_provider.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _host = TextEditingController(text: '192.168.4.1');
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
      setState(() => _error = 'No se pudo conectar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              session.connected ? Icons.check_circle : Icons.link_off,
              color: session.connected ? Colors.green : Colors.grey,
            ),
            title: Text(session.connected
                ? (session.simulated
                    ? 'Conectado (robot simulado)'
                    : 'Conectado al robot')
                : 'Sin conexión'),
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
          onPressed:
              _busy ? null : () => _run(() => ctrl.connectReal(_host.text.trim())),
          icon: const Icon(Icons.wifi),
          label: const Text('Conectar al robot'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _run(ctrl.connectSimulated),
          icon: const Icon(Icons.science),
          label: const Text('Modo simulación'),
        ),
        if (session.connected) ...[
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
