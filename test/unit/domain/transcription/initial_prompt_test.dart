import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/transcription/domain/usecases/build_initial_prompt.dart';

void main() {
  const buildInitialPrompt = BuildInitialPrompt();
  final at = DateTime.utc(2026, 1, 1);

  GlossaryTerm term(String value) {
    return GlossaryTerm(
      id: GlossaryTermId('term-$value'),
      projectId: const ProjectId('project-1'),
      term: value,
      termSortKey: value.toLowerCase(),
      createdAt: at,
      updatedAt: at,
    );
  }

  test('sin términos devuelve cadena vacía (FR-014)', () {
    expect(buildInitialPrompt(const []), '');
  });

  test('convierte el glosario en una lista plana de términos', () {
    final prompt = buildInitialPrompt([term('backlog'), term('sprint')]);
    expect(prompt, 'backlog, sprint');
  });
}
