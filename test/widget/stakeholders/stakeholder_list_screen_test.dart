import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_list_provider.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_list_screen.dart';

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: StakeholderListScreen(projectId: 'p1')),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      stakeholderListProvider('p1').overrideWith((ref) => const Stream<StakeholderListState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra los interesados', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    await _pump(
      tester,
      stakeholderListProvider('p1').overrideWith(
        (ref) => Stream.value(
          StakeholderListState(
            stakeholders: [
              Stakeholder(
                id: const StakeholderId('s1'),
                projectId: const ProjectId('p1'),
                name: 'Ana',
                influence: InfluenceLevel.high,
                status: StakeholderStatus.active,
                createdAt: at,
                updatedAt: at,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('vacía: invita a crear el primer interesado', (tester) async {
    await _pump(
      tester,
      stakeholderListProvider('p1')
          .overrideWith((ref) => Stream.value(const StakeholderListState(stakeholders: []))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Crea el primero'), findsOneWidget);
  });

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      stakeholderListProvider('p1')
          .overrideWith((ref) => Stream<StakeholderListState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });
}
