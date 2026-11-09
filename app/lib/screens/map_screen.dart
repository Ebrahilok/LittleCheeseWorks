import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_state.dart';
import '../models/world.dart';
import '../providers/robot_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Offset? _selected;

  Offset _toMap(Offset local, Size size, Room room) => room.clamp(Offset(
        room.minX + local.dx / size.width * room.width,
        room.minY + local.dy / size.height * room.height,
      ));

  Future<void> _savePoint() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar punto'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && _selected != null) {
      ref.read(robotProvider.notifier).savePoint(name.text.trim(), _selected!);
    }
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(robotProvider);
    final ctrl = ref.read(robotProvider.notifier);
    final room = s.room;
    final canSend = s.connected &&
        s.status.state == RobotState.listo &&
        s.status.hasLoad &&
        _selected != null;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: AspectRatio(
                aspectRatio: room.width / room.height,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = Size(box.maxWidth, box.maxHeight);
                    return GestureDetector(
                      onTapUp: (d) =>
                          setState(() => _selected = _toMap(d.localPosition, size, room)),
                      onLongPressStart: (d) {
                        final p = _toMap(d.localPosition, size, room);
                        ctrl.simulator?.placeObject(p.dx, p.dy);
                      },
                      child: CustomPaint(
                        key: const Key('mapCanvas'),
                        size: size,
                        painter: _MapPainter(
                          room: room,
                          status: s.status,
                          objects: s.objects,
                          selected: _selected,
                          points: s.savedPoints,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selected == null
                    ? 'Toca el mapa para elegir el destino'
                    : 'Destino: (${_selected!.dx.toStringAsFixed(2)}, ${_selected!.dy.toStringAsFixed(2)}) m'),
                if (s.savedPoints.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final p in s.savedPoints)
                        InputChip(
                          label: Text(p.name),
                          onPressed: () => setState(() => _selected = p.position),
                          onDeleted: () => ctrl.deletePoint(p),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSend ? () => ctrl.goTo(_selected!) : null,
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Llevar aquí'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _selected == null ? null : _savePoint,
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
                if (!canSend)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      !s.connected
                          ? 'Conéctate al robot (pestaña Preparar).'
                          : s.status.state == RobotState.esperandoCarga
                              ? 'Primero coloca la carga en la base y calibra (pestaña Preparar).'
                              : s.status.state != RobotState.listo
                                  ? 'El robot está ocupado: ${s.status.state.label}.'
                                  : '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (s.simulated)
                  Text('Simulación: mantén pulsado el mapa para colocar un objeto.',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.room,
    required this.status,
    required this.objects,
    required this.selected,
    required this.points,
  });

  final Room room;
  final RobotStatus status;
  final List<DetectedObject> objects;
  final Offset? selected;
  final List<SavedPoint> points;

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / room.width;
    final sy = size.height / room.height;
    Offset c(double x, double y) => Offset((x - room.minX) * sx, (y - room.minY) * sy);

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7F4EC));
    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = room.minX.ceilToDouble(); x <= room.maxX; x += 1) {
      canvas.drawLine(c(x, room.minY), c(x, room.maxY), grid);
    }
    for (var y = room.minY.ceilToDouble(); y <= room.maxY; y += 1) {
      canvas.drawLine(c(room.minX, y), c(room.maxX, y), grid);
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF8A8F98));

    // Base.
    canvas.drawRect(
        Rect.fromCenter(center: c(0, 0), width: 0.5 * sx, height: 0.5 * sy),
        Paint()..color = const Color(0x6643A047));
    _label(canvas, 'Base', c(0, 0) + Offset(-14, 0.3 * sy));

    for (final p in points) {
      canvas.drawCircle(c(p.x, p.y), 5, Paint()..color = Colors.purple);
      _label(canvas, p.name, c(p.x, p.y) + const Offset(-14, 7));
    }

    for (final o in objects) {
      canvas.drawRect(
          Rect.fromCenter(center: c(o.x, o.y), width: o.w * sx, height: o.h * sy),
          Paint()..color = const Color(0xFFD84315));
    }

    // Destino y trayectoria.
    final t = status.target ?? selected;
    if (status.target != null) {
      canvas.drawLine(
          c(status.x, status.y),
          c(status.target!.dx, status.target!.dy),
          Paint()
            ..color = const Color(0xFF1E88E5)
            ..strokeWidth = 2);
    }
    if (t != null) {
      final p = c(t.dx, t.dy);
      final m = Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(p, 9, m);
      canvas.drawLine(p - const Offset(13, 0), p + const Offset(13, 0), m);
      canvas.drawLine(p - const Offset(0, 13), p + const Offset(0, 13), m);
    }

    // Robot: punto con flecha de orientación.
    final rp = c(status.x, status.y);
    canvas.drawCircle(rp, 10, Paint()..color = const Color(0xFF1565C0));
    canvas.drawLine(
        rp,
        rp + Offset(cos(status.heading), sin(status.heading)) * 18,
        Paint()
          ..color = const Color(0xFFFFEB3B)
          ..strokeWidth = 4);
    if (status.hasLoad) {
      canvas.drawCircle(rp, 4, Paint()..color = const Color(0xFFFFA000));
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.black87, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }
}
