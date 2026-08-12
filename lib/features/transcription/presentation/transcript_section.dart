import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/transcript_segment.dart';
import 'transcript_provider.dart';

/// Vista de transcripción (ui-contracts.md): resuelve `pending`, `running`,
/// `ready` y `failed` sin banderas. `pending` es un aviso con acción hacia
/// ajustes, nunca un error (T075) — es el estado correcto de FR-016, no un
/// fallo.
class TranscriptSection extends ConsumerWidget {
  const TranscriptSection({required this.recordingId, super.key});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transcriptViewProvider(recordingId));

    return AsyncScaffoldBody<TranscriptView>(
      value: state,
      isEmpty: (view) => view is TranscriptReady && view.segments.isEmpty,
      empty: (_) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('La transcripción no produjo segmentos con habla.'),
      ),
      data: (context, view) => switch (view) {
        TranscriptPending() => const _TranscriptPendingNotice(),
        TranscriptRunning() => const _TranscriptRunningNotice(),
        TranscriptReady(:final segments) => _TranscriptSegmentList(segments: segments),
        TranscriptFailed(:final reason) => _TranscriptFailedNotice(reason: reason),
      },
    );
  }
}

class _TranscriptPendingNotice extends StatelessWidget {
  const _TranscriptPendingNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: const Icon(Icons.hourglass_empty),
        title: const Text('Transcripción pendiente'),
        subtitle: const Text(
          'El modelo de transcripción todavía no está descargado. El audio se conservó.',
        ),
        trailing: TextButton(
          onPressed: () => context.go('/settings/models'),
          child: const Text('Ir a ajustes'),
        ),
      ),
    );
  }
}

class _TranscriptRunningNotice extends StatelessWidget {
  const _TranscriptRunningNotice();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text('Transcribiendo...'),
    );
  }
}

class _TranscriptFailedNotice extends StatelessWidget {
  const _TranscriptFailedNotice({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('La transcripción falló'),
        subtitle: Text(reason),
      ),
    );
  }
}

class _TranscriptSegmentList extends StatelessWidget {
  const _TranscriptSegmentList({required this.segments});

  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments)
          ListTile(
            dense: true,
            leading: Text(_formatMs(segment.fromMs)),
            title: Text(segment.text),
          ),
      ],
    );
  }

  String _formatMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
