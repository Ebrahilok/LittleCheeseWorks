import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../providers/robot_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  /// Las fallas van en rojo; las detecciones de objetos son solo informativas.
  static (IconData, Color) _look(String code) => switch (code) {
        RobotEvent.objectDetected => (Icons.radar, Colors.blueGrey),
        RobotEvent.lowBattery => (Icons.battery_alert, Colors.orange),
        RobotEvent.connectionLost => (Icons.wifi_off, Colors.red),
        RobotEvent.obstacleTimeout => (Icons.block, Colors.red),
        RobotEvent.localizationLost => (Icons.location_off, Colors.red),
        _ => (Icons.warning_amber, Colors.red),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(robotProvider).alerts;
    if (alerts.isEmpty) {
      return const Center(child: Text('Sin alertas.'));
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: ref.read(robotProvider.notifier).clearAlerts,
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Borrar historial'),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = alerts[i];
              final t = a.at;
              final (icon, color) = _look(a.event.code);
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(a.event.description),
                subtitle: Text('${two(t.hour)}:${two(t.minute)}:${two(t.second)}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
