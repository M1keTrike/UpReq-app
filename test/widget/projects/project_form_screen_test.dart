import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/data/project_repository_impl.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/project_repository.dart';
import 'package:up_req/features/projects/presentation/project_form_screen.dart';

class _FakeProjectRepository implements ProjectRepository {
  final List<Project> inserted = [];

  @override
  Future<void> insert(Project project) async => inserted.add(project);

  @override
  Future<void> update(Project project) async {}

  @override
  Future<Project?> findById(ProjectId id) async => null;

  @override
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at) async {}

  @override
  Stream<List<Project>> watchByStatus(ProjectStatus status) => Stream.value(const []);

  @override
  Stream<Project?> watchById(ProjectId id) => Stream.value(null);

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) =>
      Stream.value(const ProjectCounters(stakeholders: 0, sessions: 0, glossaryTerms: 0));
}

void main() {
  testWidgets(
    'validación fallida: no guarda, señala el campo y conserva lo escrito en el resto (FR-022)',
    (tester) async {
      final repository = _FakeProjectRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [projectRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProjectFormScreen(projectId: null)),
        ),
      );
      await tester.pumpAndSettle();

      // Nombre queda vacío (inválido); descripción sí se rellena.
      await tester.enterText(
        find.widgetWithText(TextField, 'Descripción'),
        'Una descripción cualquiera',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(repository.inserted, isEmpty);
      expect(find.text('El nombre del proyecto es obligatorio.'), findsOneWidget);
      expect(find.text('Una descripción cualquiera'), findsOneWidget);
    },
  );
}
