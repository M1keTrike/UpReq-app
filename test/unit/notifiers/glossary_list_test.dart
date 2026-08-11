import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';
import 'package:up_req/features/glossary/presentation/glossary_list_provider.dart';

import '../../support/test_container.dart';

/// El provider consulta `projectStatusReaderProvider` para derivar
/// `isReadOnly` (FR-004a); sin este doble lanzaría `UnimplementedError`.
class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

class _FakeGlossaryRepository implements GlossaryRepository {
  List<GlossaryTerm> terms = [];

  @override
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id) => Stream.value(terms);

  @override
  Future<GlossaryTerm?> findById(GlossaryTermId id) => throw UnimplementedError();

  @override
  Future<void> insert(GlossaryTerm term) => throw UnimplementedError();

  @override
  Future<void> update(GlossaryTerm term) => throw UnimplementedError();

  @override
  Future<void> softDelete(GlossaryTermId id, DateTime at) => throw UnimplementedError();
}

void main() {
  test('expone los términos del proyecto a través de un único provider', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeGlossaryRepository()
      ..terms = [
        GlossaryTerm(
          id: const GlossaryTermId('t1'),
          projectId: const ProjectId('p1'),
          term: 'Requisito',
          termSortKey: 'requisito',
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [
        glossaryRepositoryProvider.overrideWithValue(repository),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
      ],
    );
    container.listen(glossaryListProvider('p1'), (_, _) {});

    final state = await container.read(glossaryListProvider('p1').future);

    expect(state.terms.map((t) => t.term), ['Requisito']);
    expect(state.isReadOnly, isFalse);
  });
}
