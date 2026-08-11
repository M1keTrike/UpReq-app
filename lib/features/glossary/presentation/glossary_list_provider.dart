import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/glossary_repository_impl.dart';
import '../domain/entities/glossary_term.dart';
import '../domain/usecases/watch_glossary.dart';

part 'glossary_list_provider.g.dart';

final class GlossaryListState {
  const GlossaryListState({required this.terms, this.isReadOnly = false});

  final List<GlossaryTerm> terms;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): oculta las acciones
  /// de escritura (crear, eliminar) cuando el proyecto está cerrado. El
  /// valor por defecto `false` mantiene compatibilidad con las pruebas que
  /// construyen el estado directamente sin pasar por el provider.
  final bool isReadOnly;
}

/// Único provider que consume la pantalla de lista de glosario
/// (ui-contracts.md, pantalla 7).
@riverpod
Stream<GlossaryListState> glossaryList(Ref ref, String projectId) {
  final repository = ref.watch(glossaryRepositoryProvider);
  final statusReader = ref.watch(projectStatusReaderProvider);
  return WatchGlossary(repository)(ProjectId(projectId)).asyncMap((terms) async {
    final isActive = await statusReader.isActive(ProjectId(projectId));
    return GlossaryListState(terms: terms, isReadOnly: !isActive);
  });
}
