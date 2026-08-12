import 'package:up_req/core/domain/ids.dart';

import '../entities/recording.dart';

abstract interface class RecordingRepository {
  Stream<List<Recording>> watchBySession(SessionId id); // FR-003a

  Stream<Recording?> watchActive(); // invariante R1

  Future<Recording?> findInterrupted(); // FR-011, al arrancar

  Future<Recording?> findById(RecordingId id);

  Future<void> insert(Recording recording);

  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at);

  Future<void> setStopped(RecordingId id, int durationMs, DateTime at);

  /// Baja lógica + asiento `recordingDeleted` en la MISMA transacción, y
  /// cascada que retira marcas, transcripciones y segmentos de esa
  /// grabación sin escribir asientos propios (FR-023).
  Future<void> softDelete(RecordingId id, DateTime at);
}
