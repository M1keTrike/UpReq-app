import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/core/domain/session_status_reader.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';
import 'package:up_req/features/recordings/data/record_audio_recorder.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/data/wav_writer.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/transcription/data/model_repository_impl.dart';
import 'package:up_req/features/transcription/data/whisper_transcriber.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';

import '../../support/fake_audio_recorder.dart';
import '../../support/fake_glossary_repository.dart';
import '../../support/fake_model_repository.dart';
import '../../support/fake_transcriber.dart';
import '../../support/test_container.dart';

class _FakeRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};
  Recording? active;

  @override
  Future<void> insert(Recording recording) async {
    store[recording.id.value] = recording;
    active = recording;
  }

  @override
  Stream<Recording?> watchActive() => Stream.value(active);

  @override
  Stream<Recording?> watchById(RecordingId id) => Stream.value(store[id.value]);

  @override
  Stream<List<Recording>> watchBySession(SessionId id) => throw UnimplementedError();

  @override
  Future<Recording?> findInterrupted() async => null;

  @override
  Future<Recording?> findById(RecordingId id) async => store[id.value];

  @override
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) async {
    active = null;
    final current = store[id.value]!;
    store[id.value] = current.copyWith(
      status: RecordingStatus.stopped,
      durationMs: durationMs,
      stoppedAt: at,
      updatedAt: at,
    );
  }

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) async {}

  @override
  Future<void> softDelete(RecordingId id, DateTime at) async {}
}

class _FakeWavSink implements WavSink {
  bool isOpen = false;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    isOpen = true;
  }

  @override
  Future<void> append(Uint8List pcmFrames) async {}

  @override
  Future<int> closeAndFinalize() async {
    isOpen = false;
    return 1000;
  }

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async => 1000;

  @override
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    isOpen = true;
  }
}

class _FakeSessionStatusReader implements SessionStatusReader {
  @override
  Future<SessionSnapshot?> find(SessionId id) async {
    return const SessionSnapshot(projectId: ProjectId('project-1'), isInProgress: true);
  }
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

void main() {
  test('con el modelo base disponible, los parciales de la pasada en vivo llegan a livePartial', () async {
    final recorder = FakeAudioRecorder();
    final transcriber = FakeTranscriber();
    final modelRepository = FakeModelRepository()..available.add(TranscriptionModel.base);

    final container = buildTestContainer(
      overrides: [
        audioRecorderProvider.overrideWithValue(recorder),
        wavSinkProvider.overrideWithValue(_FakeWavSink()),
        recordingRepositoryProvider.overrideWithValue(_FakeRecordingRepository()),
        sessionStatusReaderProvider.overrideWithValue(_FakeSessionStatusReader()),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
        modelRepositoryProvider.overrideWithValue(modelRepository),
        transcriberProvider.overrideWithValue(transcriber),
        glossaryRepositoryProvider.overrideWithValue(FakeGlossaryRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(activeCaptureProvider.notifier);
    final result = await notifier.start(const SessionId('session-1'));
    expect(result, isA<Ok<RecordingId>>());

    // StartLivePass corre en paralelo a _beginCapture (unawaited): darle una
    // vuelta al bucle de eventos para que la suscripción quede lista.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCaptureProvider)!.livePartial, isNull);

    transcriber.emitPartial('y entonces');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(activeCaptureProvider)!.livePartial, 'y entonces');

    transcriber.emitPartial('y entonces el usuario dijo');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(activeCaptureProvider)!.livePartial, 'y entonces el usuario dijo');

    await notifier.stop();
    expect(transcriber.liveStopped, isTrue);
  });

  test('sin el modelo base disponible, la captura funciona sin pasada en vivo', () async {
    final recorder = FakeAudioRecorder();
    final transcriber = FakeTranscriber();
    final modelRepository = FakeModelRepository(); // vacío: ningún modelo disponible

    final container = buildTestContainer(
      overrides: [
        audioRecorderProvider.overrideWithValue(recorder),
        wavSinkProvider.overrideWithValue(_FakeWavSink()),
        recordingRepositoryProvider.overrideWithValue(_FakeRecordingRepository()),
        sessionStatusReaderProvider.overrideWithValue(_FakeSessionStatusReader()),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
        modelRepositoryProvider.overrideWithValue(modelRepository),
        transcriberProvider.overrideWithValue(transcriber),
        glossaryRepositoryProvider.overrideWithValue(FakeGlossaryRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(activeCaptureProvider.notifier);
    final result = await notifier.start(const SessionId('session-1'));
    expect(result, isA<Ok<RecordingId>>());

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeCaptureProvider), isNotNull);
    expect(container.read(activeCaptureProvider)!.livePartial, isNull);
    expect(transcriber.lastModel, isNull, reason: 'transcribeLive no debe invocarse sin modelo');

    final stopResult = await notifier.stop();
    expect(stopResult, isA<Ok<void>>());
  });
}
