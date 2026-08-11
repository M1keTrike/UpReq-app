import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart' hide ScriptPoint;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/sessions/data/script_point_repository_impl.dart';
import 'package:up_req/features/sessions/data/script_points_dao.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ScriptPointRepositoryImpl repository;
  final at = DateTime.utc(2026, 1, 1);

  setUp(() async {
    db = openTestDatabase();
    repository = ScriptPointRepositoryImpl(db, ScriptPointsDao(db), SequentialIdGenerator(prefix: 'audit'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
  });

  tearDown(() => db.close());

  Future<void> appendPoint(String id, String text) async {
    final current = await repository.watchBySession(const SessionId('session-1')).first;
    await repository.append(
      ScriptPoint(
        id: ScriptPointId(id),
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        text: text,
        status: ScriptPointStatus.pending,
        position: current.length,
        createdAt: at,
        updatedAt: at,
      ),
    );
  }

  Future<List<ScriptPoint>> livePoints() => repository.watchBySession(const SessionId('session-1')).first;

  void expectContiguousPositions(List<ScriptPoint> points) {
    final positions = points.map((p) => p.position).toList()..sort();
    expect(positions, List.generate(points.length, (i) => i), reason: 'posiciones deben ser 0..n-1 sin huecos ni duplicados');
  }

  test('invariante I3: agregar toma position = n', () async {
    await appendPoint('sp0', 'Punto 0');
    await appendPoint('sp1', 'Punto 1');
    await appendPoint('sp2', 'Punto 2');

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points.map((p) => p.id.value), ['sp0', 'sp1', 'sp2']);
  });

  test('invariante I3: reordenar hacia el final desplaza el rango intermedio', () async {
    await appendPoint('sp0', 'Punto 0');
    await appendPoint('sp1', 'Punto 1');
    await appendPoint('sp2', 'Punto 2');
    await appendPoint('sp3', 'Punto 3');

    // Mover sp0 (position 0) a la posición 2: sp1 y sp2 se desplazan -1.
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp0'), 0, 2);

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points.map((p) => p.id.value), ['sp1', 'sp2', 'sp0', 'sp3']);
  });

  test('invariante I3: reordenar hacia el principio desplaza el rango intermedio', () async {
    await appendPoint('sp0', 'Punto 0');
    await appendPoint('sp1', 'Punto 1');
    await appendPoint('sp2', 'Punto 2');
    await appendPoint('sp3', 'Punto 3');

    // Mover sp3 (position 3) a la posición 0: sp0..sp2 se desplazan +1.
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp3'), 3, 0);

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points.map((p) => p.id.value), ['sp3', 'sp0', 'sp1', 'sp2']);
  });

  test('invariante I3: movimientos repetidos a los extremos mantienen 0..n-1', () async {
    for (var i = 0; i < 5; i++) {
      await appendPoint('sp$i', 'Punto $i');
    }

    await repository.move(const SessionId('session-1'), const ScriptPointId('sp4'), 4, 0);
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp0'), 1, 4);
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp2'), 3, 3);
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp3'), 4, 1);

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points, hasLength(5));
  });

  test('invariante I3: eliminar compacta -1 las posiciones mayores', () async {
    await appendPoint('sp0', 'Punto 0');
    await appendPoint('sp1', 'Punto 1');
    await appendPoint('sp2', 'Punto 2');
    await appendPoint('sp3', 'Punto 3');

    await repository.softDelete(const ScriptPointId('sp1'), at.add(const Duration(days: 1)));

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points.map((p) => p.id.value), ['sp0', 'sp2', 'sp3']);
  });

  test('invariante I3: secuencia combinada de agregar, reordenar y eliminar', () async {
    for (var i = 0; i < 5; i++) {
      await appendPoint('sp$i', 'Punto $i');
    }

    await repository.move(const SessionId('session-1'), const ScriptPointId('sp1'), 1, 3);
    await repository.softDelete(const ScriptPointId('sp0'), at.add(const Duration(days: 1)));
    await appendPoint('sp5', 'Punto 5');
    await repository.move(const SessionId('session-1'), const ScriptPointId('sp5'), 4, 0);
    await repository.softDelete(const ScriptPointId('sp3'), at.add(const Duration(days: 2)));

    final points = await livePoints();
    expectContiguousPositions(points);
    expect(points, hasLength(4));
  });

  test(
    'visibilidad transitiva: con la sesión eliminada lógicamente, watchBySession devuelve '
    'lista vacía aunque los puntos conserven deleted_at nulo',
    () async {
      await appendPoint('sp0', 'Punto 0');
      await appendPoint('sp1', 'Punto 1');

      await (db.update(db.sessions)..where((s) => s.id.equals('session-1')))
          .write(SessionsCompanion(deletedAt: Value(at.add(const Duration(days: 1)))));

      final points = await livePoints();
      expect(points, isEmpty);

      final rows = await db.select(db.scriptPoints).get();
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.deletedAt == null), isTrue);
    },
  );
}
