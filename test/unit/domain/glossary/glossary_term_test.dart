import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  test('== y hashCode comparan por valor', () {
    GlossaryTerm build({String term = 'Requisito'}) => GlossaryTerm(
          id: const GlossaryTermId('t1'),
          projectId: const ProjectId('p1'),
          term: term,
          termSortKey: term.toLowerCase(),
          definition: 'Definición',
          notes: 'Notas',
          createdAt: at,
          updatedAt: at,
        );

    final a = build();
    final b = build();
    final c = build(term: 'Otro');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
    expect(a, isNot(equals(Object())));
    expect(a.toString(), contains('Requisito'));
  });
}
