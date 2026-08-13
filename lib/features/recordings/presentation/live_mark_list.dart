import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/live_mark.dart';
import 'live_marks_provider.dart';
import 'recording_mutations.dart';

/// Lista de marcas de una grabación, ordenada por instante, cada una con su
/// tipo visible (ui-contracts.md, pantalla 3). Cambiar el tipo y eliminar
/// solo se ofrecen fuera de solo lectura: la revisión ocurre después de
/// detener la grabación, no en vivo, así que aquí sí cabe un menú.
class LiveMarkList extends ConsumerWidget {
  const LiveMarkList({required this.recordingId, this.isReadOnly = false, super.key});

  final RecordingId recordingId;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(liveMarksProvider(recordingId.value));

    return switch (marksAsync) {
      AsyncData(:final value) when value.isNotEmpty => Column(
          children: [for (final mark in value) _MarkTile(mark: mark, isReadOnly: isReadOnly)],
        ),
      AsyncData() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Sin marcas en esta grabación.'),
        ),
      AsyncError() => const SizedBox.shrink(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _MarkTile extends ConsumerWidget {
  const _MarkTile({required this.mark, required this.isReadOnly});

  final LiveMark mark;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = mark.atMs ~/ 1000;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return ListTile(
      leading: Icon(_iconFor(mark.kind)),
      title: Text(_labelFor(mark.kind)),
      trailing: isReadOnly
          ? Text('$minutes:$secs')
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$minutes:$secs'),
                PopupMenuButton<LiveMarkKind>(
                  key: Key('mark-kind-menu-${mark.id.value}'),
                  tooltip: 'Cambiar tipo',
                  icon: const Icon(Icons.edit_outlined),
                  onSelected: (kind) => runChangeMarkKind(ref, mark.id, kind),
                  itemBuilder: (context) => [
                    for (final kind in LiveMarkKind.values)
                      PopupMenuItem(value: kind, child: Text(_labelFor(kind))),
                  ],
                ),
                IconButton(
                  key: Key('mark-delete-${mark.id.value}'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar marca',
                  onPressed: () => runDeleteLiveMark(ref, mark.id),
                ),
              ],
            ),
    );
  }

  static IconData _iconFor(LiveMarkKind kind) => switch (kind) {
        LiveMarkKind.requirement => Icons.assignment_outlined,
        LiveMarkKind.doubt => Icons.help_outline,
        LiveMarkKind.quote => Icons.format_quote_outlined,
      };

  static String _labelFor(LiveMarkKind kind) => switch (kind) {
        LiveMarkKind.requirement => 'Posible requisito',
        LiveMarkKind.doubt => 'Duda',
        LiveMarkKind.quote => 'Cita textual',
      };
}
