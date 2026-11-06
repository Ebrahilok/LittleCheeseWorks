import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../providers/robot_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  Color _color(RobotState s) => switch (s) {
        RobotState.reposo => Colors.blueGrey,
        RobotState.enRuta || RobotState.regresando => Colors.blue,
        RobotState.obstaculo => Colors.orange,
        RobotState.esperando => Colors.green,
        RobotState.error || RobotState.paro => Colors.red,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    final st = session.status;

    if (!session.connected) {
      return const Center(child: Text('Sin conexión con el robot.'));
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: _color(st.state))),
                if (st.table != null) Text('Mesa ${st.table}'),
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
        if (st.obstacle)
          const ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text('Obstáculo al frente'),
          ),
        const SizedBox(height: 12),
        if (st.state == RobotState.esperando)
          FilledButton.icon(
            onPressed: ctrl.confirmDelivery,
            icon: const Icon(Icons.check),
            label: const Text('Recibido'),
          ),
        if (st.state.isFault)
          FilledButton.tonalIcon(
            onPressed: ctrl.reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reiniciar a reposo'),
          ),
        if (session.simulated) ...[
          const Divider(height: 32),
          Text('Controles de simulación',
              style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                  onPressed: () => ctrl.simulator?.placeObstacle(),
                  child: const Text('Poner obstáculo')),
              OutlinedButton(
                  onPressed: () => ctrl.simulator?.clearObstacle(),
                  child: const Text('Quitar obstáculo')),
              OutlinedButton(
                  onPressed: () => ctrl.simulator?.loseLine(),
                  child: const Text('Perder línea')),
            ],
          ),
        ],
      ],
    );
  }
}
