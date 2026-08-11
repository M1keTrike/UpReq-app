import 'package:up_req/core/domain/ids.dart';

enum InfluenceLevel { high, medium, low }

enum StakeholderStatus { active, inactive }

/// Interesado dentro de un proyecto (FR-005, FR-006, FR-007). Inmutable.
final class Stakeholder {
  const Stakeholder({
    required this.id,
    required this.projectId,
    required this.name,
    required this.influence,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.area,
    this.notes,
  });

  final StakeholderId id;
  final ProjectId projectId;
  final String name;
  final String? role;
  final String? area;
  final InfluenceLevel influence;
  final String? notes;
  final StakeholderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Stakeholder &&
      other.id == id &&
      other.projectId == projectId &&
      other.name == name &&
      other.role == role &&
      other.area == area &&
      other.influence == influence &&
      other.notes == notes &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        name,
        role,
        area,
        influence,
        notes,
        status,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Stakeholder($id, $name, $influence, $status)';
}
