import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/recording.dart';
import 'active_capture_notifier.dart';
import 'live_mark_bar.dart';
import 'recording_mutations.dart';
import 'recovery_sheet.dart';
import 'session_capture_provider.dart';

/// Sección de captura del detalle de sesión (ui-contracts.md, pantalla 1).
/// Fail-closed: mientras el provider carga, `canRecord` es `false` — el
/// control de grabar no debe parpadear ni un instante con proyecto cerrado
/// o sesión planeada (aprendizaje del incremento 1, anotado en el roadmap).
class SessionCaptureSection extends ConsumerStatefulWidget {
  const SessionCaptureSection({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionCaptureSection> createState() => _SessionCaptureSectionState();
}

class _SessionCaptureSectionState extends ConsumerState<SessionCaptureSection> {
  String? _sheetShownForRecordingId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionCaptureProvider(widget.sessionId));
    final canRecord = state.value?.canRecord ?? false;
    final active = state.value?.active;
    final recordings = state.value?.recordings ?? const [];
    final interrupted = state.value?.interrupted;

    _maybeShowRecoverySheet(interrupted, canRecord);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grabación', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (active != null) ...[
          _ActiveCaptureView(active: active),
          const SizedBox(height: 8),
          LiveMarkBar(active: active),
        ] else if (canRecord)
          FilledButton.icon(
            key: const Key('start-recording-button'),
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Grabar entrevista'),
            onPressed: () => runStartRecording(ref, SessionId(widget.sessionId)),
          ),
        if (recordings.isEmpty && active == null && canRecord)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Todavía no hay grabaciones. Toca «Grabar entrevista» para empezar.'),
          )
        else
          for (final recording in recordings)
            _RecordingTile(recording: recording, isReadOnly: !canRecord),
      ],
    );
  }

  /// Se dispara la primera vez que aparece una grabación `interrupted` de
  /// esta sesión; no se repite mientras siga siendo la misma (T066: no
  /// descartable sin elegir, así que reabrirla en cada rebuild sería ruido,
  /// no una segunda oportunidad).
  void _maybeShowRecoverySheet(Recording? interrupted, bool canRecord) {
    if (interrupted == null) {
      _sheetShownForRecordingId = null;
      return;
    }
    if (_sheetShownForRecordingId == interrupted.id.value) return;
    _sheetShownForRecordingId = interrupted.id.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showRecoverySheet(context, ref, interrupted: interrupted, canResume: canRecord);
    });
  }
}

class _ActiveCaptureView extends ConsumerWidget {
  const _ActiveCaptureView({required this.active});

  final ActiveCapture active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = active.elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (active.elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.fiber_manual_record, color: Colors.red),
            const SizedBox(width: 8),
            Text('Grabando · $minutes:$seconds'),
            const Spacer(),
            OutlinedButton(
              key: const Key('stop-recording-button'),
              onPressed: () => runStopRecording(ref),
              child: const Text('Detener'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingTile extends ConsumerWidget {
  const _RecordingTile({required this.recording, required this.isReadOnly});

  final Recording recording;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = recording.durationMs ~/ 1000;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return ListTile(
      leading: const Icon(Icons.mic),
      title: Text('Grabación $minutes:$secs'),
      subtitle: Text(_statusLabel(recording.status)),
      onTap: () => context.go(
        '/projects/${recording.projectId.value}/sessions/${recording.sessionId.value}'
        '/recordings/${recording.id.value}',
      ),
      trailing: isReadOnly
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar grabación',
              onPressed: () => runDeleteRecording(ref, recording.id),
            ),
    );
  }

  static String _statusLabel(RecordingStatus status) => switch (status) {
        RecordingStatus.recording => 'En curso',
        RecordingStatus.stopped => 'Detenida',
        RecordingStatus.interrupted => 'Interrumpida',
      };
}
