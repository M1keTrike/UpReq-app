import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';
import 'package:up_req/features/glossary/presentation/glossary_form_screen.dart';

/// El provider de `CreateGlossaryTerm` resuelve `projectStatusReaderProvider`
/// al construirse (inyección de dependencias), antes incluso de que `call()`
/// llegue a validar el borrador. Sin este doble, la construcción del
/// provider lanzaría `UnimplementedError` (core/domain/project_status_reader.dart)
/// y la prueba nunca llegaría a ejercitar la validación.
class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

class _FakeGlossaryRepository implements GlossaryRepository {
  final List<GlossaryTerm> inserted = [];

  @override
  Future<void> insert(GlossaryTerm term) async => inserted.add(term);

  @override
  Future<void> update(GlossaryTerm term) async {}

  @override
  Future<GlossaryTerm?> findById(GlossaryTermId id) async => null;

  @override
  Future<void> softDelete(GlossaryTermId id, DateTime at) async {}

  @override
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id) => Stream.value(const []);
}

void main() {
  testWidgets(
    'validación fallida: no guarda y conserva lo escrito en el resto (FR-022)',
    (tester) async {
      final repository = _FakeGlossaryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            glossaryRepositoryProvider.overrideWithValue(repository),
            projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
          ],
          child: const MaterialApp(home: GlossaryFormScreen(projectId: 'p1', termId: null)),
        ),
      );
      await tester.pumpAndSettle();

      // Término queda vacío (inválido); definición sí se rellena.
      await tester.enterText(
        find.widgetWithText(TextField, 'Definición'),
        'Una definición cualquiera',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(repository.inserted, isEmpty);
      expect(find.text('El término es obligatorio.'), findsOneWidget);
      expect(find.text('Una definición cualquiera'), findsOneWidget);
    },
  );
}
