import 'package:up_req/core/domain/ids.dart';

import '../entities/transcript.dart';
import '../entities/transcript_segment.dart';

abstract interface class TranscriptRepository {
  Stream<Transcript?> watchByRecordingAndPass(RecordingId id, TranscriptPass pass);

  Stream<List<TranscriptSegment>> watchSegments(TranscriptId id);

  /// Cola de FR-016: transcripciones `pending` a la espera de que el modelo
  /// llegue.
  Future<List<Transcript>> findPending();

  Future<void> upsert(Transcript transcript);

  /// Reemplaza los segmentos de una transcripción en una sola transacción.
  Future<void> replaceSegments(TranscriptId id, List<TranscriptSegment> segments);

  /// Baja lógica en cascada, invocada ÚNICAMENTE desde la baja de la
  /// grabación de la que provienen y dentro de esa misma transacción
  /// (`RecordingRepositoryImpl.softDelete`). FR-023 acota este incremento a
  /// no exponer eliminación individual de transcripciones ni de segmentos:
  /// ninguna pantalla llama a este método.
  Future<void> softDeleteByRecording(RecordingId id, DateTime at);
}
