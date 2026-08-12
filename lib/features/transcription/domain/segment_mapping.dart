import 'package:up_req/core/domain/ids.dart';

import 'contracts/transcriber.dart';
import 'entities/transcript_segment.dart';

/// Mapea la salida cruda del transcriptor a la unidad de evidencia del
/// sistema. FUNCIÓN PURA: los identificadores de segmento y el instante se
/// reciben ya calculados, nunca se generan aquí, para que la prueba no
/// dependa de infraestructura. `position` es el índice `0..n-1` dentro de
/// [raw] (invariante S2); `from_ms`/`to_ms` pasan tal cual desde
/// [RawSegment] (invariante S1, garantizada por el transcriptor).
List<TranscriptSegment> mapRawSegments({
  required List<RawSegment> raw,
  required List<SegmentId> ids,
  required TranscriptId transcriptId,
  required RecordingId recordingId,
  required SessionId sessionId,
  required ProjectId projectId,
  required DateTime now,
}) {
  assert(ids.length == raw.length, 'ids y raw deben tener la misma longitud.');
  return [
    for (var i = 0; i < raw.length; i++)
      TranscriptSegment(
        id: ids[i],
        transcriptId: transcriptId,
        recordingId: recordingId,
        sessionId: sessionId,
        projectId: projectId,
        fromMs: raw[i].fromMs,
        toMs: raw[i].toMs,
        position: i,
        text: raw[i].text,
        createdAt: now,
        updatedAt: now,
      ),
  ];
}
