import 'package:up_req/core/domain/ids.dart';

/// Estado de un punto del guion (FR-011): libre entre los tres, en cualquier
/// dirección y en cualquier momento, incluso con la sesión cerrada, siempre
/// que el proyecto esté activo.
enum ScriptPointStatus { pending, covered, skipped }

/// Punto del guion de una sesión (FR-010, FR-011). Inmutable. `position` es
/// contigua `0..n-1` dentro de la sesión (invariante I3, mantenido por el
/// repositorio, no por el esquema). `projectId` va desnormalizado igual que
/// en la fila, para que el dominio pueda comprobar `ProjectStatusReader` sin
/// consultar la sesión.
final class ScriptPoint {
  const ScriptPoint({
    required this.id,
    required this.sessionId,
    required this.projectId,
    required this.text,
    required this.status,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final ScriptPointId id;
  final SessionId sessionId;
  final ProjectId projectId;
  final String text;
  final ScriptPointStatus status;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScriptPoint copyWith({
    String? text,
    ScriptPointStatus? status,
    int? position,
    DateTime? updatedAt,
  }) {
    return ScriptPoint(
      id: id,
      sessionId: sessionId,
      projectId: projectId,
      text: text ?? this.text,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptPoint &&
      other.id == id &&
      other.sessionId == sessionId &&
      other.projectId == projectId &&
      other.text == text &&
      other.status == status &&
      other.position == position &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        projectId,
        text,
        status,
        position,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'ScriptPoint($id, "$text", $status, pos:$position)';
}
