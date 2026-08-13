import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/usecases/watch_active_segment.dart';

import '../data/transcript_repository_impl.dart';
import '../domain/entities/transcript.dart';
import '../domain/entities/transcript_segment.dart';

part 'transcript_provider.g.dart';

/// Resuelve `pending`, `running`, `ready` y `failed` de la transcripción
/// definitiva de una grabación sin banderas (constitución, Principio I):
/// clase sealed exhaustiva, no un `TranscriptStatus` más un booleano suelto.
sealed class TranscriptView {
  const TranscriptView();
}

/// FR-016: sin modelo disponible al cerrar la sesión. Se presenta como
/// aviso con acción hacia ajustes, nunca como error (T075).
final class TranscriptPending extends TranscriptView {
  const TranscriptPending();
}

/// La sesión de esta grabación todavía no se cerró: `RunFinalPass` (FR-013)
/// solo se dispara al cerrar, así que todavía no existe ninguna fila
/// `Transcript`, ni siquiera `pending`. Distinto de [TranscriptPending]: aquí
/// el modelo puede estar perfectamente descargado — el motivo de no haber
/// transcripción es otro, y decir "falta el modelo" sería engañoso (bug
/// real: la pantalla de detalle de grabación es alcanzable con la sesión
/// todavía en curso desde `_RecordingTile`, T093).
final class TranscriptNotStarted extends TranscriptView {
  const TranscriptNotStarted();
}

/// FR-015: la pasada definitiva se está procesando; no bloquea el resto de
/// la interfaz.
final class TranscriptRunning extends TranscriptView {
  const TranscriptRunning();
}

final class TranscriptReady extends TranscriptView {
  const TranscriptReady({required this.transcript, required this.segments});

  final Transcript transcript;
  final List<TranscriptSegment> segments;
}

final class TranscriptFailed extends TranscriptView {
  const TranscriptFailed({required this.reason});

  final String reason;
}

/// `transcriptViewProvider(recordingId)`.
@riverpod
Stream<TranscriptView> transcriptView(Ref ref, String recordingId) {
  final repository = ref.watch(transcriptRepositoryProvider);
  final id = RecordingId(recordingId);

  return repository.watchByRecordingAndPass(id, TranscriptPass.finalPass).asyncExpand((transcript) {
    if (transcript == null) return Stream.value(const TranscriptNotStarted());

    return switch (transcript.status) {
      TranscriptStatus.pending => Stream.value(const TranscriptPending()),
      TranscriptStatus.processing => Stream.value(const TranscriptRunning()),
      TranscriptStatus.failed =>
        Stream.value(TranscriptFailed(reason: transcript.failureReason ?? 'Fallo desconocido.')),
      TranscriptStatus.done => repository
          .watchSegments(transcript.id)
          .map((segments) => TranscriptReady(transcript: transcript, segments: segments)),
    };
  });
}

/// FR-019: el segmento que contiene la posición actual del reproductor, o
/// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.
@riverpod
Stream<SegmentId?> activeSegment(Ref ref, String transcriptId) {
  final watchActiveSegment = ref.watch(watchActiveSegmentProvider);
  return watchActiveSegment(TranscriptId(transcriptId));
}
