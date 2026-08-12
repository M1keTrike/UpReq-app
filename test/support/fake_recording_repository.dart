import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';

/// Doble en memoria de `RecordingRepository`, reutilizable entre pruebas de
/// transcripción que solo necesitan resolver una grabación por id.
class FakeRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};
  Recording? active;

  @override
  Future<void> insert(Recording recording) async {
    store[recording.id.value] = recording;
    if (recording.status == RecordingStatus.recording) active = recording;
  }

  @override
  Stream<Recording?> watchActive() => Stream.value(active);

  @override
  Stream<Recording?> watchById(RecordingId id) => Stream.value(store[id.value]);

  @override
  Stream<List<Recording>> watchBySession(SessionId id) {
    return Stream.value(store.values.where((r) => r.sessionId == id).toList());
  }

  @override
  Future<Recording?> findInterrupted() async => null;

  @override
  Future<Recording?> findById(RecordingId id) async => store[id.value];

  @override
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(
      status: RecordingStatus.stopped,
      durationMs: durationMs,
      stoppedAt: at,
      updatedAt: at,
    );
    active = null;
  }

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
  }

  @override
  Future<void> softDelete(RecordingId id, DateTime at) async {
    store.remove(id.value);
  }
}
