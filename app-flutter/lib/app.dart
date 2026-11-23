import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/robot_provider.dart';
import 'screens/alerts_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/map_screen.dart';
import 'screens/view3d_screen.dart';
import 'screens/status_screen.dart';

class RobotCargaApp extends StatelessWidget {
  const RobotCargaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Robot de Carga',
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
      MapScreen(),
      View3DScreen(),
      StatusScreen(),
      AlertsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot de Carga'),
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
      body: Column(
        children: [
          if (session.reconnecting)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const ListTile(
                dense: true,
                leading: Icon(Icons.wifi_off),
                title: Text('Conexión perdida con el robot. Reconectando…'),
              ),
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 4) ref.read(robotProvider.notifier).markAlertsRead();
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.wifi), label: 'Preparar'),
          const NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          const NavigationDestination(
              icon: Icon(Icons.view_in_ar), label: '3D'),
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
