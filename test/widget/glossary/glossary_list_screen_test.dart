import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/presentation/glossary_list_provider.dart';
import 'package:up_req/features/glossary/presentation/glossary_list_screen.dart';

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: GlossaryListScreen(projectId: 'p1')),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      glossaryListProvider('p1').overrideWith((ref) => const Stream<GlossaryListState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra los términos', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    await _pump(
      tester,
      glossaryListProvider('p1').overrideWith(
        (ref) => Stream.value(
          GlossaryListState(
            terms: [
              GlossaryTerm(
                id: const GlossaryTermId('t1'),
                projectId: const ProjectId('p1'),
                term: 'Requisito',
                termSortKey: 'requisito',
                createdAt: at,
                updatedAt: at,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requisito'), findsOneWidget);
  });

  testWidgets('vacía: invita a agregar el primer término (FR-020, SC-005)', (tester) async {
    await _pump(
      tester,
      glossaryListProvider('p1').overrideWith((ref) => Stream.value(const GlossaryListState(terms: []))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Crea el primero'), findsOneWidget);
  });

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      glossaryListProvider('p1').overrideWith((ref) => Stream<GlossaryListState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });
}
