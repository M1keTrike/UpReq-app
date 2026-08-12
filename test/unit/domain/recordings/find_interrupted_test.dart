import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/find_interrupted.dart';

class _FakeRecordingRepository implements RecordingRepository {
  Recording? active;
  Recording? interrupted;
  RecordingId? promotedId;

  @override
  Stream<Recording?> watchActive() => Stream.value(active);

  @override
  Stream<Recording?> watchById(RecordingId id) => throw UnimplementedError();

  @override
  Future<Recording?> findInterrupted() async => interrupted;

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) async {
    promotedId = id;
    if (active?.id == id && status == RecordingStatus.interrupted) {
      interrupted = active!.copyWith(status: RecordingStatus.interrupted, updatedAt: at);
      active = null;
    }
  }

  @override
  Future<Recording?> findById(RecordingId id) => throw UnimplementedError();

  @override
  Future<void> insert(Recording recording) => throw UnimplementedError();

  @override
  Stream<List<Recording>> watchBySession(SessionId id) => throw UnimplementedError();

  @override
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) => throw UnimplementedError();

  @override
  Future<void> softDelete(RecordingId id, DateTime at) => throw UnimplementedError();
}

void main() {
  final at = DateTime.utc(2026, 1, 1);

  test(
    'una grabación que quedó en recording de una ejecución anterior se reporta como interrumpida',
    () async {
      final repository = _FakeRecordingRepository()
        ..active = Recording(
          id: const RecordingId('recording-1'),
          sessionId: const SessionId('session-1'),
          projectId: const ProjectId('project-1'),
          filePath: 'recordings/recording-1.wav',
          status: RecordingStatus.recording,
          durationMs: 0,
          sampleRate: 16000,
          channels: 1,
          startedAt: at,
          createdAt: at,
          updatedAt: at,
        );

      final useCase = FindInterrupted(repository, Clock.fixed(at));
      final result = await useCase();

      expect(result, isNotNull);
      expect(result!.id.value, 'recording-1');
      expect(result.status, RecordingStatus.interrupted);
      expect(repository.promotedId, const RecordingId('recording-1'));
    },
  );

  test('sin grabaciones huérfanas ni interrumpidas, devuelve null', () async {
    final repository = _FakeRecordingRepository();
    final useCase = FindInterrupted(repository, Clock.fixed(at));

    final result = await useCase();
    expect(result, isNull);
  });
}
