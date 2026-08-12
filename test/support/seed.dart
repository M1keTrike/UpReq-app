/// Constructores de datos de prueba para las seis entidades, a nivel de fila
/// de drift (no de entidad de dominio, que cada historia define en su propia
/// fase). Permite que las pruebas de DAO de cada historia siembren datos sin
/// depender de las demás. Todo parámetro tiene un valor por defecto salvo el
/// reloj (`at`), que siempre debe venir del reloj de prueba para que las
/// fechas sean deterministas.
library;

import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';

ProjectsCompanion seedProject({
  required DateTime at,
  String id = 'project-1',
  String name = 'Proyecto de prueba',
  String? client,
  String? description,
  String status = 'active',
}) {
  return ProjectsCompanion.insert(
    id: id,
    name: name,
    client: Value(client),
    description: Value(description),
    status: Value(status),
    createdAt: at,
    updatedAt: at,
  );
}

StakeholdersCompanion seedStakeholder({
  required DateTime at,
  required String projectId,
  String id = 'stakeholder-1',
  String name = 'Interesado de prueba',
  String? role,
  String? area,
  String influence = 'medium',
  String? notes,
  String status = 'active',
}) {
  return StakeholdersCompanion.insert(
    id: id,
    projectId: projectId,
    name: name,
    role: Value(role),
    area: Value(area),
    influence: influence,
    notes: Value(notes),
    status: Value(status),
    createdAt: at,
    updatedAt: at,
  );
}

SessionsCompanion seedSession({
  required DateTime at,
  required String projectId,
  String id = 'session-1',
  String title = 'Sesión de prueba',
  DateTime? scheduledAt,
  String technique = 'openInterview',
  String? location,
  String status = 'planned',
  String? notes,
  DateTime? closedAt,
  DateTime? deletedAt,
}) {
  return SessionsCompanion.insert(
    id: id,
    projectId: projectId,
    title: title,
    scheduledAt: scheduledAt ?? at,
    technique: technique,
    location: Value(location),
    status: Value(status),
    notes: Value(notes),
    closedAt: Value(closedAt),
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

SessionParticipantsCompanion seedSessionParticipant({
  required DateTime at,
  required String sessionId,
  required String stakeholderId,
  required String projectId,
}) {
  return SessionParticipantsCompanion.insert(
    sessionId: sessionId,
    stakeholderId: stakeholderId,
    projectId: projectId,
    createdAt: at,
  );
}

ScriptPointsCompanion seedScriptPoint({
  required DateTime at,
  required String sessionId,
  required String projectId,
  required int position,
  String id = 'script-point-1',
  String body = 'Punto de guion de prueba',
  String status = 'pending',
  DateTime? deletedAt,
}) {
  return ScriptPointsCompanion.insert(
    id: id,
    sessionId: sessionId,
    projectId: projectId,
    body: body,
    status: Value(status),
    position: position,
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

GlossaryTermsCompanion seedGlossaryTerm({
  required DateTime at,
  required String projectId,
  String id = 'glossary-term-1',
  String term = 'Término de prueba',
  String? definition,
  String? notes,
  String? termSortKey,
  DateTime? deletedAt,
}) {
  return GlossaryTermsCompanion.insert(
    id: id,
    projectId: projectId,
    term: term,
    definition: Value(definition),
    notes: Value(notes),
    termSortKey: termSortKey ?? term.toLowerCase(),
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

RecordingsCompanion seedRecording({
  required DateTime at,
  required String sessionId,
  required String projectId,
  String id = 'recording-1',
  String filePath = 'recordings/recording-1.wav',
  String status = 'recording',
  int durationMs = 0,
  int sampleRate = 16000,
  int channels = 1,
  DateTime? startedAt,
  DateTime? stoppedAt,
  DateTime? deletedAt,
}) {
  return RecordingsCompanion.insert(
    id: id,
    sessionId: sessionId,
    projectId: projectId,
    filePath: filePath,
    status: Value(status),
    durationMs: Value(durationMs),
    sampleRate: Value(sampleRate),
    channels: Value(channels),
    startedAt: startedAt ?? at,
    stoppedAt: Value(stoppedAt),
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

LiveMarksCompanion seedLiveMark({
  required DateTime at,
  required String recordingId,
  required String sessionId,
  required String projectId,
  String id = 'mark-1',
  String kind = 'requirement',
  int atMs = 0,
  DateTime? deletedAt,
}) {
  return LiveMarksCompanion.insert(
    id: id,
    recordingId: recordingId,
    sessionId: sessionId,
    projectId: projectId,
    kind: kind,
    atMs: atMs,
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

TranscriptsCompanion seedTranscript({
  required DateTime at,
  required String recordingId,
  required String sessionId,
  required String projectId,
  String id = 'transcript-1',
  String pass = 'final',
  String status = 'pending',
  String modelId = 'small',
  String? body,
  String? failureReason,
  DateTime? completedAt,
  DateTime? deletedAt,
}) {
  return TranscriptsCompanion.insert(
    id: id,
    recordingId: recordingId,
    sessionId: sessionId,
    projectId: projectId,
    pass: pass,
    status: Value(status),
    modelId: modelId,
    body: Value(body),
    failureReason: Value(failureReason),
    completedAt: Value(completedAt),
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

TranscriptSegmentsCompanion seedTranscriptSegment({
  required DateTime at,
  required String transcriptId,
  required String recordingId,
  required String sessionId,
  required String projectId,
  required int fromMs,
  required int toMs,
  required int position,
  String id = 'segment-1',
  String body = 'Segmento de prueba',
  DateTime? deletedAt,
}) {
  return TranscriptSegmentsCompanion.insert(
    id: id,
    transcriptId: transcriptId,
    recordingId: recordingId,
    sessionId: sessionId,
    projectId: projectId,
    fromMs: fromMs,
    toMs: toMs,
    position: position,
    body: body,
    deletedAt: Value(deletedAt),
    createdAt: at,
    updatedAt: at,
  );
}

AuditEntriesCompanion seedAuditEntry({
  required DateTime at,
  required String projectId,
  required String operation,
  required String entityType,
  required String entityId,
  String id = 'audit-entry-1',
  String? entityLabel,
}) {
  return AuditEntriesCompanion.insert(
    id: id,
    projectId: projectId,
    operation: operation,
    entityType: entityType,
    entityId: entityId,
    entityLabel: Value(entityLabel),
    occurredAt: at,
    createdAt: at,
    updatedAt: at,
  );
}
