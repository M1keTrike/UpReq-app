import 'package:up_req/core/domain/ids.dart';

/// Fragmento de texto con su ventana temporal: la unidad de evidencia de
/// todo el sistema (data-model.md). Inmutable. El campo se llama `text`,
/// aunque la columna de drift se llama `body` — colisión de `text` con el
/// método `text()` que `Table` hereda (ver `transcript_segments.dart`).
final class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.transcriptId,
    required this.recordingId,
    required this.sessionId,
    required this.projectId,
    required this.fromMs,
    required this.toMs,
    required this.position,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final SegmentId id;
  final TranscriptId transcriptId;
  final RecordingId recordingId;
  final SessionId sessionId;
  final ProjectId projectId;

  /// Inicio, relativo a la grabación. Invariante S1: `fromMs < toMs`.
  final int fromMs;

  /// Fin, relativo a la grabación.
  final int toMs;

  /// Orden contiguo `0..n-1` dentro de su transcripción (invariante S2).
  final int position;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is TranscriptSegment &&
      other.id == id &&
      other.transcriptId == transcriptId &&
      other.recordingId == recordingId &&
      other.sessionId == sessionId &&
      other.projectId == projectId &&
      other.fromMs == fromMs &&
      other.toMs == toMs &&
      other.position == position &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        transcriptId,
        recordingId,
        sessionId,
        projectId,
        fromMs,
        toMs,
        position,
        text,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'TranscriptSegment($id, $position, ${fromMs}ms-${toMs}ms)';
}
