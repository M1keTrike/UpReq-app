import 'package:up_req/core/domain/ids.dart';

import '../entities/live_mark.dart';

abstract interface class LiveMarkRepository {
  Stream<List<LiveMark>> watchByRecording(RecordingId id); // FR-008, orden por at_ms

  Future<void> insert(LiveMark mark);

  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at); // FR-009a

  /// Baja lógica + asiento `liveMarkDeleted` en la MISMA transacción.
  Future<void> softDelete(LiveMarkId id, DateTime at);
}
