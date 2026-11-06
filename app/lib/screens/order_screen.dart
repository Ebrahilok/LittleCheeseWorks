import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../providers/robot_provider.dart';

/// Número de mesas disponibles en la pista.
const int kTableCount = 6;

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    final ready = session.connected && session.status.state == RobotState.reposo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Selecciona la mesa destino',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var t = 1; t <= kTableCount; t++)
              ChoiceChip(
                label: Text('Mesa $t'),
                selected: _selected == t,
                onSelected: (_) => setState(() => _selected = t),
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: ready && _selected != null
              ? () {
                  ctrl.sendToTable(_selected!);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Robot enviado a la mesa $_selected')));
                }
              : null,
          icon: const Icon(Icons.send),
          label: const Text('Enviar pedido (carga la bandeja primero)'),
        ),
        if (!session.connected)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Conéctate al robot en la pestaña Conexión.'),
          )
        else if (!ready)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
                'El robot está ocupado (${session.status.state.label}).'),
          ),
      ],
    );
  }
}
