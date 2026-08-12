import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/live_mark.dart';
import 'live_marks_provider.dart';

/// Lista de marcas de una grabación, ordenada por instante, cada una con su
/// tipo visible (ui-contracts.md, pantalla 3).
class LiveMarkList extends ConsumerWidget {
  const LiveMarkList({required this.recordingId, super.key});

  final RecordingId recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(liveMarksProvider(recordingId.value));

    return switch (marksAsync) {
      AsyncData(:final value) when value.isNotEmpty => Column(
          children: [for (final mark in value) _MarkTile(mark: mark)],
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

class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.mark});

  final LiveMark mark;

  @override
  Widget build(BuildContext context) {
    final seconds = mark.atMs ~/ 1000;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return ListTile(
      leading: Icon(_iconFor(mark.kind)),
      title: Text(_labelFor(mark.kind)),
      trailing: Text('$minutes:$secs'),
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
