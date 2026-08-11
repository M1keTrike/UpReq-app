import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/sessions/data/session_repository_impl.dart';
import 'package:up_req/features/sessions/data/sessions_dao.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = SessionRepositoryImpl(db, SessionsDao(db), SequentialIdGenerator(prefix: 'audit'));
  });

  tearDown(() => db.close());

  test('inserta sesión y participantes en una sola transacción', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.stakeholders).insert(seedStakeholder(at: at, projectId: 'project-1', id: 's1'));
    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's2', name: 'Otro'),
        );

    await repository.insert(
      ElicitationSession(
        id: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        title: 'Entrevista',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      ),
      const [StakeholderId('s1'), StakeholderId('s2')],
    );

    final sessions = await db.select(db.sessions).get();
    expect(sessions, hasLength(1));

    final participants = await db.select(db.sessionParticipants).get();
    expect(participants, hasLength(2));
    expect(participants.map((p) => p.stakeholderId), containsAll(['s1', 's2']));
  });

  test('updated_at cambia en toda escritura (FR-016)', () async {
    final created = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: created, id: 'project-1'));
    await db.into(db.sessions).insert(seedSession(at: created, projectId: 'project-1', id: 'session-1'));

    final updateAt = created.add(const Duration(days: 1));
    await repository.updateNotes(const SessionId('session-1'), 'Notas', updateAt);

    final row = (await db.select(db.sessions).get()).single;
    expect(row.createdAt, created);
    expect(row.updatedAt, updateAt);
  });

  test('SessionCounters correcto por estado (FR-013)', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
    await db.into(db.scriptPoints).insert(
          seedScriptPoint(
            at: at,
            sessionId: 'session-1',
            projectId: 'project-1',
            id: 'sp1',
            position: 0,
            status: 'pending',
          ),
        );
    await db.into(db.scriptPoints).insert(
          seedScriptPoint(
            at: at,
            sessionId: 'session-1',
            projectId: 'project-1',
            id: 'sp2',
            position: 1,
            status: 'covered',
          ),
        );
    await db.into(db.scriptPoints).insert(
          seedScriptPoint(
            at: at,
            sessionId: 'session-1',
            projectId: 'project-1',
            id: 'sp3',
            position: 2,
            status: 'covered',
          ),
        );
    await db.into(db.scriptPoints).insert(
          seedScriptPoint(
            at: at,
            sessionId: 'session-1',
            projectId: 'project-1',
            id: 'sp4',
            position: 3,
            status: 'skipped',
          ),
        );

    final detail = await repository.watchDetail(const SessionId('session-1')).first;

    expect(detail!.counters.pending, 1);
    expect(detail.counters.covered, 2);
    expect(detail.counters.skipped, 1);
    expect(detail.counters.total, 4);
  });

  test(
    'invariante I9: eliminar una sesión con cinco puntos deja un asiento y cero filas '
    'modificadas en script_points',
    () async {
      final at = DateTime.utc(2026, 1, 1);
      await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
      await db.into(db.sessions).insert(
            seedSession(at: at, projectId: 'project-1', id: 'session-1', title: 'Sesión con guion'),
          );
      for (var i = 0; i < 5; i++) {
        await db.into(db.scriptPoints).insert(
              seedScriptPoint(at: at, sessionId: 'session-1', projectId: 'project-1', id: 'sp$i', position: i),
            );
      }

      await repository.softDelete(const SessionId('session-1'), at.add(const Duration(days: 1)));

      final auditRows = await db.select(db.auditEntries).get();
      expect(auditRows, hasLength(1));
      expect(auditRows.single.operation, 'sessionDeleted');
      expect(auditRows.single.entityLabel, 'Sesión con guion');

      final scriptPointRows = await db.select(db.scriptPoints).get();
      expect(scriptPointRows, hasLength(5));
      expect(scriptPointRows.every((p) => p.deletedAt == null), isTrue);

      // Visibilidad transitiva: una consulta que exige sesión viva no
      // devuelve ninguno de los cinco puntos, aunque su fila siga intacta.
      final aliveQuery = db.customSelect(
        'SELECT script_points.id FROM script_points '
        'JOIN sessions ON sessions.id = script_points.session_id '
        'WHERE script_points.session_id = ? AND script_points.deleted_at IS NULL '
        'AND sessions.deleted_at IS NULL',
        variables: [Variable.withString('session-1')],
        readsFrom: {db.scriptPoints, db.sessions},
      );
      final aliveRows = await aliveQuery.get();
      expect(aliveRows, isEmpty);
    },
  );

  test('invariante I10: un interesado desactivado sigue apareciendo entre los participantes', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.stakeholders).insert(seedStakeholder(at: at, projectId: 'project-1', id: 's1', name: 'Ana'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
    await db.into(db.sessionParticipants).insert(
          seedSessionParticipant(at: at, sessionId: 'session-1', stakeholderId: 's1', projectId: 'project-1'),
        );

    // Desactivar el interesado directamente: no toca session_participants.
    await (db.update(db.stakeholders)..where((s) => s.id.equals('s1')))
        .write(const StakeholdersCompanion(status: Value('inactive')));

    final detail = await repository.watchDetail(const SessionId('session-1')).first;

    expect(detail!.participantIds, [const StakeholderId('s1')]);
  });
}
