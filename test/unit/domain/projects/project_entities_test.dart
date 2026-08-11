import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/entities/project_detail.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  group('Project', () {
    test('copyWith reemplaza solo los campos indicados', () {
      final project = Project(
        id: const ProjectId('p1'),
        name: 'Original',
        client: 'Cliente',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      );

      final copy = project.copyWith(name: 'Nuevo', status: ProjectStatus.closed);

      expect(copy.name, 'Nuevo');
      expect(copy.client, 'Cliente');
      expect(copy.status, ProjectStatus.closed);
      expect(copy.id, project.id);
      expect(copy.createdAt, project.createdAt);
    });

    test('== y hashCode comparan por valor', () {
      final a = Project(
        id: const ProjectId('p1'),
        name: 'Proyecto',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final b = Project(
        id: const ProjectId('p1'),
        name: 'Proyecto',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final c = b.copyWith(name: 'Otro');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('Proyecto'));
    });
  });

  group('ProjectCounters', () {
    test('== y hashCode comparan por valor', () {
      const a = ProjectCounters(stakeholders: 1, sessions: 2, glossaryTerms: 3);
      const b = ProjectCounters(stakeholders: 1, sessions: 2, glossaryTerms: 3);
      const c = ProjectCounters(stakeholders: 0, sessions: 2, glossaryTerms: 3);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  test('ProjectDetail agrupa proyecto y contadores', () {
    final project = Project(
      id: const ProjectId('p1'),
      name: 'Proyecto',
      status: ProjectStatus.active,
      createdAt: at,
      updatedAt: at,
    );
    const counters = ProjectCounters(stakeholders: 1, sessions: 2, glossaryTerms: 3);

    final detail = ProjectDetail(project: project, counters: counters);

    expect(detail.project, project);
    expect(detail.counters, counters);
  });
}
