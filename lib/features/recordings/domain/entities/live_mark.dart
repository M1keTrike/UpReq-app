import 'package:up_req/core/domain/ids.dart';

/// Los tres tipos aclarados el 2026-08-11: posible requisito, duda y cita
/// textual. Definen las ventanas de filtrado del incremento 3.
enum LiveMarkKind { requirement, doubt, quote }

/// Marca que el analista coloca durante una grabación activa (data-model.md).
final class LiveMark {
  const LiveMark({
    required this.id,
    required this.recordingId,
    required this.sessionId,
    required this.projectId,
    required this.kind,
    required this.atMs,
    required this.createdAt,
    required this.updatedAt,
  });

  final LiveMarkId id;
  final RecordingId recordingId;
  final SessionId sessionId;
  final ProjectId projectId;
  final LiveMarkKind kind;

  /// Milisegundos desde el inicio de **su** grabación, no epoch.
  final int atMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  LiveMark copyWith({LiveMarkKind? kind, DateTime? updatedAt}) {
    return LiveMark(
      id: id,
      recordingId: recordingId,
      sessionId: sessionId,
      projectId: projectId,
      kind: kind ?? this.kind,
      atMs: atMs,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiveMark &&
      other.id == id &&
      other.recordingId == recordingId &&
      other.sessionId == sessionId &&
      other.projectId == projectId &&
      other.kind == kind &&
      other.atMs == atMs &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, recordingId, sessionId, projectId, kind, atMs, createdAt, updatedAt);

  @override
  String toString() => 'LiveMark($id, $kind, ${atMs}ms)';
}
