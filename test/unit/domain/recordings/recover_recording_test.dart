import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/recover_interrupted.dart';

class _FakeRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};

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
  }

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
  }

  @override
  Future<void> insert(Recording recording) async => store[recording.id.value] = recording;

  @override
  Stream<Recording?> watchActive() => throw UnimplementedError();

  @override
  Stream<Recording?> watchById(RecordingId id) => throw UnimplementedError();

  @override
  Stream<List<Recording>> watchBySession(SessionId id) => throw UnimplementedError();

  @override
  Future<Recording?> findInterrupted() => throw UnimplementedError();

  @override
  Future<void> softDelete(RecordingId id, DateTime at) => throw UnimplementedError();
}

class _FakeWavSink implements WavSink {
  int repairedDurationMs = 30000;
  String? repairedPath;
  String? reopenedPath;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}

  @override
  Future<void> append(Uint8List pcmFrames) async {}

  @override
  Future<int> closeAndFinalize() async => throw UnimplementedError();

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    repairedPath = relativePath;
    return repairedDurationMs;
  }

  @override
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    reopenedPath = relativePath;
  }
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const recordingId = RecordingId('recording-1');

  late _FakeRecordingRepository repository;
  late _FakeWavSink wavSink;

  setUp(() {
    repository = _FakeRecordingRepository()
      ..store['recording-1'] = Recording(
        id: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        filePath: 'recordings/recording-1.wav',
        status: RecordingStatus.interrupted,
        durationMs: 0,
        sampleRate: 16000,
        channels: 1,
        startedAt: at,
        createdAt: at,
        updatedAt: at,
      );
    wavSink = _FakeWavSink()..repairedDurationMs = 30000;
  });

  test('resume repara la cabecera y deja la grabación en recording', () async {
    final useCase = RecoverInterrupted(repository, wavSink, Clock.fixed(at));
    final result = await useCase(recordingId, RecoveryChoice.resume);

    expect(result, isA<Ok<Recording>>());
    expect(wavSink.repairedPath, 'recordings/recording-1.wav');
    final recording = (result as Ok<Recording>).value;
    expect(recording.status, RecordingStatus.recording);
    // Lo ya grabado antes del corte viaja en el `Recording` devuelto (sin
    // persistirse) para que el notifier pueda retomar el cronómetro en
    // pantalla donde se quedó, en vez de reiniciarlo a 00:00.
    expect(recording.durationMs, 30000);

    final stored = repository.store['recording-1']!;
    expect(stored.status, RecordingStatus.recording);
  });

  test('closeKeeping repara la cabecera y deja la grabación en stopped con la duración real', () async {
    final useCase = RecoverInterrupted(repository, wavSink, Clock.fixed(at));
    final result = await useCase(recordingId, RecoveryChoice.closeKeeping);

    expect(result, isA<Ok<Recording>>());
    final recording = (result as Ok<Recording>).value;
    expect(recording.status, RecordingStatus.stopped);
    expect(recording.durationMs, 30000);
    expect(recording.stoppedAt, at);

    final stored = repository.store['recording-1']!;
    expect(stored.status, RecordingStatus.stopped);
    expect(stored.durationMs, 30000);
  });
}
