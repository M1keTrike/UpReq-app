import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';
import 'package:up_req/features/sessions/domain/entities/session_counters.dart';

/// Pruebas de las entidades inmutables de la feature de sesiones que los
/// casos de uso no ejercitan por completo (copyWith, == y hashCode), en el
/// mismo estilo que test/unit/domain/projects/project_entities_test.dart y
/// test/unit/domain/stakeholders/stakeholder_entity_test.dart.
void main() {
  final at = DateTime.utc(2026, 1, 1);
  final later = DateTime.utc(2026, 2, 1);

  group('ElicitationSession', () {
    ElicitationSession build({
      String title = 'Entrevista',
      SessionStatus status = SessionStatus.planned,
    }) =>
        ElicitationSession(
          id: const SessionId('session-1'),
          projectId: const ProjectId('p1'),
          title: title,
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          status: status,
          createdAt: at,
          updatedAt: at,
        );

    test('copyWith reemplaza solo los campos indicados', () {
      final session = build();

      final copy = session.copyWith(
        title: 'Nueva',
        status: SessionStatus.closed,
        closedAt: later,
        location: 'Sala 2',
        notes: 'Notas',
        updatedAt: later,
      );

      expect(copy.title, 'Nueva');
      expect(copy.status, SessionStatus.closed);
      expect(copy.closedAt, later);
      expect(copy.location, 'Sala 2');
      expect(copy.notes, 'Notas');
      expect(copy.updatedAt, later);
      // Sin tocar: conservan el valor original.
      expect(copy.id, session.id);
      expect(copy.projectId, session.projectId);
      expect(copy.scheduledAt, session.scheduledAt);
      expect(copy.technique, session.technique);
      expect(copy.createdAt, session.createdAt);
    });

    test('copyWith sin argumentos conserva todos los valores', () {
      final session = build();
      final copy = session.copyWith();

      expect(copy, equals(session));
    });

    test('== y hashCode comparan por valor', () {
      final a = build();
      final b = build();
      final c = build(title: 'Otra');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(Object())));
      expect(a.toString(), contains('Entrevista'));
    });
  });

  group('SessionCounters', () {
    test('total suma pendientes, cubiertos y omitidos', () {
      const counters = SessionCounters(pending: 2, covered: 1, skipped: 3);

      expect(counters.total, 6);
    });

    test('== y hashCode comparan por valor', () {
      const a = SessionCounters(pending: 1, covered: 2, skipped: 3);
      const b = SessionCounters(pending: 1, covered: 2, skipped: 3);
      const c = SessionCounters(pending: 0, covered: 2, skipped: 3);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(Object())));
      expect(a.toString(), contains('pending: 1'));
    });
  });

  group('ScriptPoint', () {
    ScriptPoint build({String text = 'Punto', ScriptPointStatus status = ScriptPointStatus.pending}) =>
        ScriptPoint(
          id: const ScriptPointId('sp1'),
          sessionId: const SessionId('session-1'),
          projectId: const ProjectId('p1'),
          text: text,
          status: status,
          position: 0,
          createdAt: at,
          updatedAt: at,
        );

    test('copyWith reemplaza solo los campos indicados', () {
      final point = build();

      final copy = point.copyWith(text: 'Nuevo texto', status: ScriptPointStatus.covered, position: 3);

      expect(copy.text, 'Nuevo texto');
      expect(copy.status, ScriptPointStatus.covered);
      expect(copy.position, 3);
      expect(copy.id, point.id);
      expect(copy.sessionId, point.sessionId);
      expect(copy.projectId, point.projectId);
      expect(copy.createdAt, point.createdAt);
    });

    test('== y hashCode comparan por valor', () {
      final a = build();
      final b = build();
      final c = build(status: ScriptPointStatus.skipped);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(Object())));
      expect(a.toString(), contains('Punto'));
    });
  });
}
