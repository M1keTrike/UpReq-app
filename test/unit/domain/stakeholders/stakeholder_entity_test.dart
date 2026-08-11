import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  test('== y hashCode comparan por valor', () {
    Stakeholder build({String name = 'Ana'}) => Stakeholder(
          id: const StakeholderId('s1'),
          projectId: const ProjectId('p1'),
          name: name,
          influence: InfluenceLevel.high,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        );

    final a = build();
    final b = build();
    final c = build(name: 'Otro');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
    expect(a.toString(), contains('Ana'));
  });
}
