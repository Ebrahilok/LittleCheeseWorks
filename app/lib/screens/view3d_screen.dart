import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/robot_provider.dart';
import '../widgets/scene3d.dart';

class View3DScreen extends ConsumerStatefulWidget {
  const View3DScreen({super.key});

  @override
  ConsumerState<View3DScreen> createState() => _View3DScreenState();
}

class _View3DScreenState extends ConsumerState<View3DScreen> {
  bool _follow = false;
  int _reset = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(robotProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: Scene3D(
            status: s.status,
            objects: s.objects,
            room: s.room,
            follow: _follow,
            resetSignal: _reset,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.status.state.label}  ·  '
                      '(${s.status.x.toStringAsFixed(2)}, ${s.status.y.toStringAsFixed(2)}) m',
                    ),
                  ),
                  FilterChip(
                    label: const Text('Seguir'),
                    selected: _follow,
                    onSelected: (v) => setState(() => _follow = v),
                  ),
                  IconButton(
                    tooltip: 'Recentrar cámara',
                    icon: const Icon(Icons.center_focus_strong),
                    onPressed: () => setState(() => _reset++),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 12,
          top: 8,
          child: Text('Arrastra para girar · rueda/pellizco para zoom',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ),
      ],
    );
  }
}
