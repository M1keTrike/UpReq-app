import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';

/// Doble en memoria de `GlossaryRepository`, para probar FR-014 (glosario
/// como `initialPrompt`) sin tocar drift.
class FakeGlossaryRepository implements GlossaryRepository {
  final Map<String, GlossaryTerm> store = {};

  @override
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id) {
    return Stream.value(store.values.where((t) => t.projectId == id).toList());
  }

  @override
  Future<GlossaryTerm?> findById(GlossaryTermId id) async => store[id.value];

  @override
  Future<void> insert(GlossaryTerm term) async {
    store[term.id.value] = term;
  }

  @override
  Future<void> update(GlossaryTerm term) async {
    store[term.id.value] = term;
  }

  @override
  Future<void> softDelete(GlossaryTermId id, DateTime at) async {
    store.remove(id.value);
  }
}
