import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../providers/robot_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  Color _color(RobotState s) => switch (s) {
        RobotState.esperandoCarga => Colors.blueGrey,
        RobotState.listo => Colors.green,
        RobotState.enRuta || RobotState.regresando => Colors.blue,
        RobotState.obstaculo => Colors.orange,
        RobotState.entregando => Colors.teal,
        RobotState.error || RobotState.paro => Colors.red,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    final st = session.status;

    if (!session.connected) {
      return Center(
          child: Text(session.reconnecting
              ? 'Conexión perdida: reconectando…'
              : 'Sin conexión con el robot.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: _color(st.state).withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(st.state.label,
                    key: const Key('stateLabel'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: _color(st.state))),
                const SizedBox(height: 8),
                Text('Posición: (${st.x.toStringAsFixed(2)}, ${st.y.toStringAsFixed(2)}) m'
                    ' · ${st.hasLoad ? 'con carga' : 'sin carga'}'),
                if (st.target != null)
                  Text('Destino: (${st.target!.dx.toStringAsFixed(2)}, '
                      '${st.target!.dy.toStringAsFixed(2)}) m'
                      ' · faltan ${session.distanceToTarget!.toStringAsFixed(2)} m'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: Icon(
              st.battery <= 20 ? Icons.battery_alert : Icons.battery_full,
              color: st.battery <= 20 ? Colors.red : null),
          title: Text('Batería: ${st.battery}%'),
          subtitle: LinearProgressIndicator(value: st.battery / 100),
        ),
        ListTile(
          leading: const Icon(Icons.radar),
          title: Text('Objetos detectados: ${session.objects.length}'),
        ),
        if (st.obstacle)
          const ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text('Obstáculo al frente'),
          ),
        const SizedBox(height: 12),
        if (st.state == RobotState.entregando)
          FilledButton.icon(
            onPressed: ctrl.unload,
            icon: const Icon(Icons.check),
            label: const Text('Ya retiré la carga'),
          ),
        if (st.state.isFault)
          FilledButton.tonalIcon(
            onPressed: ctrl.reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reiniciar'),
          ),
        if (session.simulated) ...[
          const Divider(height: 32),
          Text('Simulación (coloca objetos manteniendo pulsado el mapa)',
              style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                  onPressed: () => ctrl.simulator?.removeLastObject(),
                  child: const Text('Quitar último objeto')),
              OutlinedButton(
                  onPressed: () => ctrl.simulator?.loseLocalization(),
                  child: const Text('Perder ubicación')),
            ],
          ),
        ],
      ],
    );
  }
}
