import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/robot_provider.dart';
import 'screens/alerts_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/order_screen.dart';
import 'screens/status_screen.dart';

class RobotMeseroApp extends StatelessWidget {
  const RobotMeseroApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Robot Mesero',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepOrange,
          useMaterial3: true,
        ),
        home: const HomeShell(),
      );
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(robotProvider);
    final pages = const [
      ConnectionScreen(),
      OrderScreen(),
      StatusScreen(),
      AlertsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Mesero'),
        actions: [
          if (session.connected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    ref.read(robotProvider.notifier).emergencyStop(),
                icon: const Icon(Icons.stop_circle),
                label: const Text('PARO'),
              ),
            ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) ref.read(robotProvider.notifier).markAlertsRead();
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.wifi), label: 'Conexión'),
          const NavigationDestination(
              icon: Icon(Icons.table_restaurant), label: 'Pedido'),
          const NavigationDestination(
              icon: Icon(Icons.smart_toy), label: 'Estado'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: session.unreadAlerts > 0,
              label: Text('${session.unreadAlerts}'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}
