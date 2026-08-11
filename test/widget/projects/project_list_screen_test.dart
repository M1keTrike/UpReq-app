import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/presentation/project_list_provider.dart';
import 'package:up_req/features/projects/presentation/project_list_screen.dart';

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: ProjectListScreen()),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      projectListProvider.overrideWith((ref) => const Stream<ProjectListState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra los proyectos', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    await _pump(
      tester,
      projectListProvider.overrideWith(
        (ref) => Stream.value(
          ProjectListState(
            filter: ProjectFilter.active,
            projects: [
              Project(
                id: const ProjectId('p1'),
                name: 'Proyecto Uno',
                status: ProjectStatus.active,
                createdAt: at,
                updatedAt: at,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proyecto Uno'), findsOneWidget);
  });

  testWidgets('vacía: invita a crear el primer proyecto, no un mensaje de ausencia', (tester) async {
    await _pump(
      tester,
      projectListProvider.overrideWith(
        (ref) => Stream.value(const ProjectListState(filter: ProjectFilter.active, projects: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Crea el primero'), findsOneWidget);
  });

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      projectListProvider.overrideWith((ref) => Stream<ProjectListState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });
}
