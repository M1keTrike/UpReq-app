import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/script_point.dart';
import 'script_point_mutations.dart';

/// Lista del guion (ui-contracts.md, pantalla 6). Con el proyecto activo,
/// usa `ReorderableListView` y llama a `reorderScriptPoint` con `from` y
/// `to` (FR-010); con el proyecto cerrado (`isReadOnly`), se renderiza como
/// una lista simple sin controles de escritura.
class ScriptPointList extends ConsumerWidget {
  const ScriptPointList({
    required this.sessionId,
    required this.points,
    required this.isReadOnly,
    super.key,
  });

  final SessionId sessionId;
  final List<ScriptPoint> points;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isReadOnly) {
      return Column(
        children: [for (final point in points) _ScriptPointTile(point: point, isReadOnly: true)],
      );
    }

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // `onReorderItem` (reemplaza al `onReorder` obsoleto) ya entrega
      // `newIndex` ajustado para el hueco que deja el elemento movido: no
      // hace falta restarle 1 cuando se mueve hacia adelante.
      onReorderItem: (oldIndex, newIndex) {
        if (newIndex == oldIndex) return;
        runReorderScriptPoint(ref, sessionId, points[oldIndex].id, oldIndex, newIndex);
      },
      children: [
        for (final point in points)
          _ScriptPointTile(key: ValueKey(point.id.value), point: point, isReadOnly: false),
      ],
    );
  }
}

class _ScriptPointTile extends ConsumerWidget {
  const _ScriptPointTile({required this.point, required this.isReadOnly, super.key});

  final ScriptPoint point;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(point.text),
      subtitle: Text(statusLabel(point.status)),
      trailing: isReadOnly
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<ScriptPointStatus>(
                  tooltip: 'Marcar',
                  onSelected: (status) => runMarkScriptPoint(ref, point.id, status),
                  itemBuilder: (context) => [
                    for (final status in ScriptPointStatus.values)
                      PopupMenuItem(value: status, child: Text(statusLabel(status))),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: () => runDeleteScriptPoint(ref, point.id),
                ),
              ],
            ),
    );
  }
}

String statusLabel(ScriptPointStatus status) => switch (status) {
      ScriptPointStatus.pending => 'Pendiente',
      ScriptPointStatus.covered => 'Cubierto',
      ScriptPointStatus.skipped => 'Omitido',
    };
