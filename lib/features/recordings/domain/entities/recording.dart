import 'package:up_req/core/domain/ids.dart';

/// `recording -> stopped` (terminal) o `recording -> interrupted ->
/// recording` (reanudar) / `interrupted -> stopped` (cerrar conservando). No
/// existe transición automática desde `interrupted` (data-model.md).
enum RecordingStatus { recording, stopped, interrupted }

/// Captura de audio de una sesión (data-model.md). Inmutable.
final class Recording {
  const Recording({
    required this.id,
    required this.sessionId,
    required this.projectId,
    required this.filePath,
    required this.status,
    required this.durationMs,
    required this.sampleRate,
    required this.channels,
    required this.startedAt,
    this.stoppedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final RecordingId id;
  final SessionId sessionId;
  final ProjectId projectId;

  /// Relativa al sandbox de la app, nunca absoluta.
  final String filePath;
  final RecordingStatus status;
  final int durationMs;
  final int sampleRate;
  final int channels;
  final DateTime startedAt;
  final DateTime? stoppedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recording copyWith({
    RecordingStatus? status,
    int? durationMs,
    DateTime? stoppedAt,
    DateTime? updatedAt,
  }) {
    return Recording(
      id: id,
      sessionId: sessionId,
      projectId: projectId,
      filePath: filePath,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      sampleRate: sampleRate,
      channels: channels,
      startedAt: startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Recording &&
      other.id == id &&
      other.sessionId == sessionId &&
      other.projectId == projectId &&
      other.filePath == filePath &&
      other.status == status &&
      other.durationMs == durationMs &&
      other.sampleRate == sampleRate &&
      other.channels == channels &&
      other.startedAt == startedAt &&
      other.stoppedAt == stoppedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        projectId,
        filePath,
        status,
        durationMs,
        sampleRate,
        channels,
        startedAt,
        stoppedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Recording($id, $status, ${durationMs}ms)';
}
