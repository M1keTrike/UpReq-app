import 'package:up_req/core/domain/ids.dart';

import '../contracts/transcriber.dart';

/// `live` | `final` (data-model.md). Solo `final` se persiste con texto en
/// este incremento: la pasada en vivo no ancla evidencia (FR-012) y no puede
/// producir segmentos porque su salida es un `Stream<String>` sin marcas de
/// tiempo. `finalPass` en vez de `final` porque `final` es palabra reservada
/// de Dart; `dbValue`/`fromDbValue` hacen el mapeo explícito con la columna.
enum TranscriptPass {
  live,
  finalPass;

  String get dbValue => this == TranscriptPass.finalPass ? 'final' : 'live';

  static TranscriptPass fromDbValue(String value) {
    return value == 'final' ? TranscriptPass.finalPass : TranscriptPass.live;
  }
}

/// `pending -> processing -> done` (terminal) o `-> failed`, con reintento
/// posible desde `failed` de vuelta a `pending` (data-model.md). `pending`
/// es lo que resuelve FR-016: sin modelo disponible, no es un error.
enum TranscriptStatus { pending, processing, done, failed }

/// Resultado de una pasada de transcripción sobre una grabación
/// (data-model.md). Inmutable.
final class Transcript {
  const Transcript({
    required this.id,
    required this.recordingId,
    required this.sessionId,
    required this.projectId,
    required this.pass,
    required this.status,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
    this.text,
    this.failureReason,
    this.completedAt,
  });

  final TranscriptId id;
  final RecordingId recordingId;
  final SessionId sessionId;
  final ProjectId projectId;
  final TranscriptPass pass;
  final TranscriptStatus status;
  final TranscriptionModel modelId;

  /// Texto completo; nulo mientras no esté `done`.
  final String? text;
  final String? failureReason;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transcript copyWith({
    TranscriptStatus? status,
    String? text,
    String? failureReason,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return Transcript(
      id: id,
      recordingId: recordingId,
      sessionId: sessionId,
      projectId: projectId,
      pass: pass,
      status: status ?? this.status,
      modelId: modelId,
      text: text ?? this.text,
      failureReason: failureReason ?? this.failureReason,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Transcript &&
      other.id == id &&
      other.recordingId == recordingId &&
      other.sessionId == sessionId &&
      other.projectId == projectId &&
      other.pass == pass &&
      other.status == status &&
      other.modelId == modelId &&
      other.text == text &&
      other.failureReason == failureReason &&
      other.completedAt == completedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        recordingId,
        sessionId,
        projectId,
        pass,
        status,
        modelId,
        text,
        failureReason,
        completedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Transcript($id, ${pass.dbValue}, $status)';
}
