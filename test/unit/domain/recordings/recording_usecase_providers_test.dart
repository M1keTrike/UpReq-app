import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/data/just_audio_player.dart';
import 'package:up_req/features/recordings/data/live_mark_repository_impl.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/data/wav_writer.dart';
import 'package:up_req/features/recordings/domain/contracts/live_mark_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/change_mark_kind.dart';
import 'package:up_req/features/recordings/domain/usecases/delete_live_mark.dart';
import 'package:up_req/features/recordings/domain/usecases/delete_recording.dart';
import 'package:up_req/features/recordings/domain/usecases/find_interrupted.dart';
import 'package:up_req/features/recordings/domain/usecases/handle_storage_full.dart';
import 'package:up_req/features/recordings/domain/usecases/recover_interrupted.dart';
import 'package:up_req/features/recordings/domain/usecases/seek_to_segment.dart';
import 'package:up_req/features/transcription/data/transcript_repository_impl.dart';

import '../../../support/fake_audio_playback.dart';
import '../../../support/fake_recording_repository.dart';
import '../../../support/fake_transcript_repository.dart';
import '../../../support/test_container.dart';

class _FakeLiveMarkRepository implements LiveMarkRepository {
  final Map<String, LiveMark> store = {};

  @override
  Future<void> insert(LiveMark mark) async => store[mark.id.value] = mark;

  @override
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(kind: kind, updatedAt: at);
  }

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) async => store.remove(id.value);

  @override
  Stream<List<LiveMark>> watchByRecording(RecordingId id) => Stream.value(store.values.toList());
}

class _FakeWavSink implements WavSink {
  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}

  @override
  Future<void> append(Uint8List pcmFrames) async {}

  @override
  Future<int> closeAndFinalize() async => 1000;

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async => 1000;

  @override
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const recordingId = RecordingId('recording-1');
  const markId = LiveMarkId('mark-1');

  late FakeRecordingRepository recordingRepository;
  late _FakeLiveMarkRepository liveMarkRepository;

  setUp(() async {
    recordingRepository = FakeRecordingRepository();
    // `insert` (a diferencia de escribir `store` a mano) también marca
    // `active` cuando el estado es `recording`: lo necesita FindInterrupted,
    // que lee `watchActive()`.
    await recordingRepository.insert(
      Recording(
        id: recordingId,
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
      ),
    );
    liveMarkRepository = _FakeLiveMarkRepository()
      ..store['mark-1'] = LiveMark(
        id: markId,
        recordingId: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        kind: LiveMarkKind.requirement,
        atMs: 1000,
        createdAt: at,
        updatedAt: at,
      );
  });

  test('DeleteRecording, resuelto vía provider, da de baja la grabación', () async {
    final container = buildTestContainer(
      overrides: [recordingRepositoryProvider.overrideWithValue(recordingRepository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(deleteRecordingProvider)(recordingId);

    expect(result, isA<Ok<void>>());
    expect(recordingRepository.store.containsKey('recording-1'), isFalse);
  });

  test('DeleteLiveMark, resuelto vía provider, da de baja la marca', () async {
    final container = buildTestContainer(
      overrides: [liveMarkRepositoryProvider.overrideWithValue(liveMarkRepository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(deleteLiveMarkProvider)(markId);

    expect(result, isA<Ok<void>>());
    expect(liveMarkRepository.store.containsKey('mark-1'), isFalse);
  });

  test('ChangeMarkKind, resuelto vía provider, cambia el tipo', () async {
    final container = buildTestContainer(
      overrides: [liveMarkRepositoryProvider.overrideWithValue(liveMarkRepository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(changeMarkKindProvider)(markId, LiveMarkKind.quote);

    expect(result, isA<Ok<void>>());
    expect(liveMarkRepository.store['mark-1']!.kind, LiveMarkKind.quote);
  });

  test('FindInterrupted, resuelto vía provider, promueve la grabación huérfana', () async {
    final container = buildTestContainer(
      overrides: [recordingRepositoryProvider.overrideWithValue(recordingRepository)],
    );
    addTearDown(container.dispose);

    // FakeRecordingRepository.findInterrupted() no lee del store (siempre
    // null); lo que este caso de uso hace realmente es promover la
    // grabación huérfana antes de reportarla, que es lo que se verifica.
    await container.read(findInterruptedProvider)();

    expect(recordingRepository.store['recording-1']!.status, RecordingStatus.interrupted);
  });

  test('RecoverInterrupted, resuelto vía provider, repara y reanuda', () async {
    final container = buildTestContainer(
      overrides: [
        recordingRepositoryProvider.overrideWithValue(recordingRepository),
        wavSinkProvider.overrideWithValue(_FakeWavSink()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(recoverInterruptedProvider)(recordingId, RecoveryChoice.resume);

    expect(result, isA<Ok<Recording>>());
    expect((result as Ok<Recording>).value.status, RecordingStatus.recording);
  });

  test('HandleStorageFull, resuelto vía provider, detiene conservando lo capturado', () async {
    final container = buildTestContainer(
      overrides: [
        recordingRepositoryProvider.overrideWithValue(recordingRepository),
        wavSinkProvider.overrideWithValue(_FakeWavSink()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(handleStorageFullProvider)(recordingId);

    expect(result, isA<Err<void>>());
    expect(recordingRepository.store['recording-1']!.status, RecordingStatus.stopped);
  });

  test('SeekToSegment, resuelto vía provider, rechaza un segmento inexistente', () async {
    final container = buildTestContainer(
      overrides: [
        transcriptRepositoryProvider.overrideWithValue(FakeTranscriptRepository()),
        audioPlaybackProvider.overrideWithValue(FakeAudioPlayback()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(seekToSegmentProvider)(const SegmentId('missing'));

    expect(result, isA<Err<void>>());
  });
}
