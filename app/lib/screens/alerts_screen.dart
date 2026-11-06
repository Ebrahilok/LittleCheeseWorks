import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/robot_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(robotProvider).alerts;
    if (alerts.isEmpty) {
      return const Center(child: Text('Sin alertas.'));
    }
    return ListView.separated(
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final a = alerts[i];
        final t = a.at;
        String two(int n) => n.toString().padLeft(2, '0');
        return ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          title: Text(a.event.description),
          subtitle: Text('${two(t.hour)}:${two(t.minute)}:${two(t.second)}'),
        );
      },
    );
  }
}
