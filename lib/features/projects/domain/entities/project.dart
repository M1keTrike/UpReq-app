import 'package:up_req/core/domain/ids.dart';

enum ProjectStatus { active, closed }

/// Unidad raíz de trabajo (FR-002, FR-003). Inmutable: toda escritura pasa
/// por un `ProjectDraft` y produce una instancia nueva.
final class Project {
  const Project({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.description,
  });

  final ProjectId id;
  final String name;
  final String? client;
  final String? description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project copyWith({
    String? name,
    String? client,
    String? description,
    ProjectStatus? status,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      client: client ?? this.client,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.client == client &&
      other.description == description &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, client, description, status, createdAt, updatedAt);

  @override
  String toString() => 'Project($id, $name, $status)';
}
