import 'package:up_req/core/domain/ids.dart';

/// Técnica de elicitación usada en la sesión (FR-008).
enum SessionTechnique {
  openInterview,
  structuredInterview,
  workshop,
  observation,
  documentReview,
}

/// Avance en un solo sentido, sin retroceso ni reapertura (FR-008a):
/// `planned → inProgress → closed`. Ver `session_transition.dart`.
enum SessionStatus { planned, inProgress, closed }

/// Sesión de elicitación dentro de un proyecto (FR-008, FR-008a, FR-008b,
/// FR-009). Inmutable: toda escritura pasa por un `SessionDraft` o por los
/// casos de uso de transición/notas y produce una instancia nueva.
final class ElicitationSession {
  const ElicitationSession({
    required this.id,
    required this.projectId,
    required this.title,
    required this.scheduledAt,
    required this.technique,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.notes,
    this.closedAt,
  });

  final SessionId id;
  final ProjectId projectId;
  final String title;
  final DateTime scheduledAt;
  final SessionTechnique technique;
  final String? location;
  final SessionStatus status;
  final String? notes;

  /// Se sella al pasar a `closed`; `null` en otro caso.
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ElicitationSession copyWith({
    String? title,
    DateTime? scheduledAt,
    SessionTechnique? technique,
    String? location,
    SessionStatus? status,
    String? notes,
    DateTime? closedAt,
    DateTime? updatedAt,
  }) {
    return ElicitationSession(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      technique: technique ?? this.technique,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ElicitationSession &&
      other.id == id &&
      other.projectId == projectId &&
      other.title == title &&
      other.scheduledAt == scheduledAt &&
      other.technique == technique &&
      other.location == location &&
      other.status == status &&
      other.notes == notes &&
      other.closedAt == closedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        title,
        scheduledAt,
        technique,
        location,
        status,
        notes,
        closedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'ElicitationSession($id, $title, $status)';
}
