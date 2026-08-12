import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/core/domain/session_status_reader.dart';
import 'package:up_req/features/recordings/data/record_audio_recorder.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/data/wav_writer.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/transcription/data/model_repository_impl.dart';

import '../../support/fake_audio_recorder.dart';
import '../../support/fake_model_repository.dart';
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
  final List<Uint8List> appended = [];

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    isOpen = true;
  }

  @override
  Future<void> append(Uint8List pcmFrames) async {
    appended.add(pcmFrames);
  }

  @override
  Future<int> closeAndFinalize() async {
    isOpen = false;
    return appended.length * 10;
  }

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    return appended.length * 10;
  }

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
  test('el estado avanza de reposo a capturando, el tiempo progresa y detener libera el recurso', () async {
    final recorder = FakeAudioRecorder();
    final wavSink = _FakeWavSink();
    final repository = _FakeRecordingRepository();

    final container = buildTestContainer(
      overrides: [
        audioRecorderProvider.overrideWithValue(recorder),
        wavSinkProvider.overrideWithValue(wavSink),
        recordingRepositoryProvider.overrideWithValue(repository),
        sessionStatusReaderProvider.overrideWithValue(_FakeSessionStatusReader()),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
        // Vacío: ningún modelo disponible, así que StartLivePass omite la
        // pasada en vivo sin tocar el archivo real del modelo (T102 lo
        // resuelve con path_provider, que no existe en este entorno).
        modelRepositoryProvider.overrideWithValue(FakeModelRepository()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(activeCaptureProvider), isNull);

    final notifier = container.read(activeCaptureProvider.notifier);
    final result = await notifier.start(const SessionId('session-1'));
    expect(result, isA<Ok<RecordingId>>());

    final active = container.read(activeCaptureProvider);
    expect(active, isNotNull);
    expect(active!.elapsed, Duration.zero);
    expect(wavSink.isOpen, isTrue);
    expect(recorder.started, isTrue);

    recorder.emitFrame(Uint8List.fromList([1, 2, 3, 4]));
    await Future<void>.delayed(Duration.zero);
    expect(wavSink.appended, hasLength(1));

    // El tiempo transcurrido progresa: el ticker interno corre cada segundo.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final ticking = container.read(activeCaptureProvider);
    expect(ticking!.elapsed, greaterThan(Duration.zero));

    final stopResult = await notifier.stop();
    expect(stopResult, isA<Ok<void>>());
    expect(container.read(activeCaptureProvider), isNull);
    expect(wavSink.isOpen, isFalse);
  });
}
