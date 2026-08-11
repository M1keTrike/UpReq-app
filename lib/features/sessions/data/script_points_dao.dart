import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/script_points.dart';
import 'package:up_req/core/database/tables/sessions.dart';

part 'script_points_dao.g.dart';

/// `alive()`: un punto es vivo si su propio `deleted_at` es nulo **y** la
/// sesión a la que pertenece también lo es (visibilidad transitiva,
/// data-model.md). Las dos condiciones viven aquí, en el único sitio por
/// donde pasan las lecturas de puntos: un filtro que solo mirara el
/// `deleted_at` del punto resucitaría los puntos de sesiones eliminadas.
@DriftAccessor(tables: [ScriptPoints, Sessions])
class ScriptPointsDao extends DatabaseAccessor<AppDatabase> with _$ScriptPointsDaoMixin {
  ScriptPointsDao(super.db);

  Stream<List<ScriptPoint>> watchBySession(String sessionId) {
    final query = select(scriptPoints).join([
      innerJoin(sessions, sessions.id.equalsExp(scriptPoints.sessionId)),
    ])
      ..where(
        scriptPoints.sessionId.equals(sessionId) &
            scriptPoints.deletedAt.isNull() &
            sessions.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm(expression: scriptPoints.position)]);

    return query.watch().map((rows) => rows.map((row) => row.readTable(scriptPoints)).toList());
  }

  Future<ScriptPoint?> findById(String id) async {
    final query = select(scriptPoints).join([
      innerJoin(sessions, sessions.id.equalsExp(scriptPoints.sessionId)),
    ])
      ..where(
        scriptPoints.id.equals(id) &
            scriptPoints.deletedAt.isNull() &
            sessions.deletedAt.isNull(),
      );

    final row = await query.getSingleOrNull();
    return row?.readTable(scriptPoints);
  }

  Future<void> insertPoint(ScriptPointsCompanion companion) => into(scriptPoints).insert(companion);

  Future<void> updatePoint(String id, ScriptPointsCompanion companion) {
    return (update(scriptPoints)..where((p) => p.id.equals(id))).write(companion);
  }

  /// Desplazamiento en bloque de `from` a `to`, dentro de una transacción
  /// propia del DAO (decisión 8 de research.md). No asienta bitácora —el
  /// catálogo de FR-015 no incluye el reordenamiento— así que puede
  /// autocontenerse sin depender de la transacción del repositorio.
  Future<void> movePosition(String sessionId, String scriptPointId, int from, int to) async {
    if (from == to) return;

    await transaction(() async {
      final List<ScriptPoint> affected;
      final int delta;
      if (from < to) {
        delta = -1;
        affected = await (select(scriptPoints)
              ..where(
                (p) =>
                    p.sessionId.equals(sessionId) &
                    p.deletedAt.isNull() &
                    p.position.isBiggerThanValue(from) &
                    p.position.isSmallerOrEqualValue(to),
              ))
            .get();
      } else {
        delta = 1;
        affected = await (select(scriptPoints)
              ..where(
                (p) =>
                    p.sessionId.equals(sessionId) &
                    p.deletedAt.isNull() &
                    p.position.isBiggerOrEqualValue(to) &
                    p.position.isSmallerThanValue(from),
              ))
            .get();
      }

      for (final row in affected) {
        await (update(scriptPoints)..where((p) => p.id.equals(row.id)))
            .write(ScriptPointsCompanion(position: Value(row.position + delta)));
      }

      await (update(scriptPoints)..where((p) => p.id.equals(scriptPointId)))
          .write(ScriptPointsCompanion(position: Value(to)));
    });
  }

  /// Compacta `-1` todas las posiciones vivas mayores que la eliminada,
  /// dentro de la sesión. Primitiva usada por
  /// `ScriptPointRepositoryImpl.softDelete` dentro de su propia transacción
  /// (T089), que además marca `deleted_at` y asienta bitácora.
  Future<void> compactPositionsAfter(String sessionId, int deletedPosition) async {
    final affected = await (select(scriptPoints)
          ..where(
            (p) =>
                p.sessionId.equals(sessionId) &
                p.deletedAt.isNull() &
                p.position.isBiggerThanValue(deletedPosition),
          ))
        .get();

    for (final row in affected) {
      await (update(scriptPoints)..where((p) => p.id.equals(row.id)))
          .write(ScriptPointsCompanion(position: Value(row.position - 1)));
    }
  }
}
