import 'package:up_req/core/domain/ids.dart';

import 'entities/script_point.dart';

abstract interface class ScriptPointRepository {
  /// Vivos y ordenados por position. "Vivo" = deleted_at nulo Y sesión viva:
  /// el helper `alive()` del DAO lleva ambas condiciones, no solo la
  /// primera (visibilidad transitiva, data-model.md).
  Stream<List<ScriptPoint>> watchBySession(SessionId id);

  /// Igual que `watchBySession`, sujeto a la misma visibilidad transitiva:
  /// `null` si el punto ya no existe, está eliminado o su sesión lo está.
  Future<ScriptPoint?> findById(ScriptPointId id);

  /// Inserta en position = n. FR-010. Sin asiento de bitácora: el catálogo
  /// de FR-015 no incluye altas.
  Future<void> append(ScriptPoint point);

  Future<void> updateText(ScriptPointId id, String text, DateTime at);

  Future<void> setStatus(ScriptPointId id, ScriptPointStatus status, DateTime at);

  /// Desplazamiento en bloque en una transacción; mantiene el invariante
  /// `0..n-1` (decisión 8 de research.md).
  Future<void> move(SessionId session, ScriptPointId id, int from, int to);

  /// Marca deleted_at, compacta posiciones y asienta bitácora, todo en una
  /// transacción.
  Future<void> softDelete(ScriptPointId id, DateTime at);
}
