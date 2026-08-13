import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';
import 'package:up_req/features/recordings/presentation/recording_mutations.dart';

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
        TranscriptNotStarted() => const _TranscriptNotStartedNotice(),
        TranscriptPending() => const _TranscriptPendingNotice(),
        TranscriptRunning() => const _TranscriptRunningNotice(),
        TranscriptReady(:final transcript, :final segments) =>
          _TranscriptSegmentList(transcriptId: transcript.id.value, segments: segments),
        TranscriptFailed(:final reason) => _TranscriptFailedNotice(reason: reason),
      },
    );
  }
}

class _TranscriptNotStartedNotice extends StatelessWidget {
  const _TranscriptNotStartedNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.schedule_outlined),
        title: Text('Todavía no hay transcripción'),
        subtitle: Text('Se genera automáticamente al cerrar la sesión.'),
      ),
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

/// Resalta el segmento activo a partir del stream de posición (T095,
/// FR-019), sin temporizador propio: `activeSegmentProvider` ya recalcula
/// solo cuando la posición o los segmentos cambian. Tocar un segmento
/// dispara `seekToSegment` (FR-018).
class _TranscriptSegmentList extends ConsumerWidget {
  const _TranscriptSegmentList({required this.transcriptId, required this.segments});

  final String transcriptId;
  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSegmentId = ref.watch(activeSegmentProvider(transcriptId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments)
          ListTile(
            key: Key('segment-${segment.id.value}'),
            dense: true,
            selected: segment.id == activeSegmentId,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
            leading: Text(_formatMs(segment.fromMs)),
            title: Text(segment.text),
            onTap: () async {
              try {
                await runSeekToSegment(ref, segment.id);
              } catch (_) {
                // El estado de la Mutation (MutationError) ya refleja el fallo.
              }
            },
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
