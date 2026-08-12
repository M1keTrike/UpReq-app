import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/core/domain/session_status_reader.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/start_recording.dart';
import 'package:up_req/features/recordings/domain/usecases/stop_recording.dart';

import '../../../support/fake_audio_recorder.dart';

class _FakeRecordingRepository implements RecordingRepository {
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
  Stream<List<Recording>> watchBySession(SessionId id) => throw UnimplementedError();

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

class _FakeSessionStatusReader implements SessionStatusReader {
  _FakeSessionStatusReader(this.snapshot);

  SessionSnapshot? snapshot;

  @override
  Future<SessionSnapshot?> find(SessionId id) async => snapshot;
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  _FakeProjectStatusReader({this.active = true});

  final bool active;

  @override
  Future<bool> isActive(ProjectId id) async => active;
}

class _FakeWavSink implements WavSink {
  int durationToReturn = 0;
  bool opened = false;
  bool closed = false;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    opened = true;
  }

  @override
  Future<void> append(Uint8List pcmFrames) async {}

  @override
  Future<int> closeAndFinalize() async {
    closed = true;
    return durationToReturn;
  }
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);
  final String _id;
  @override
  String generate() => _id;
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const sessionId = SessionId('session-1');
  const projectId = ProjectId('project-1');

  late _FakeRecordingRepository repository;
  late FakeAudioRecorder audioRecorder;

  setUp(() {
    repository = _FakeRecordingRepository();
    audioRecorder = FakeAudioRecorder();
  });

  group('StartRecording', () {
    StartRecording build({
      SessionSnapshot? snapshot = const SessionSnapshot(
        projectId: projectId,
        isInProgress: true,
      ),
      bool projectActive = true,
      String id = 'recording-1',
    }) {
      return StartRecording(
        repository,
        _FakeSessionStatusReader(snapshot),
        _FakeProjectStatusReader(active: projectActive),
        audioRecorder,
        _FixedIdGenerator(id),
        Clock.fixed(at),
      );
    }

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      final useCase = build(projectActive: false);
      final result = await useCase(sessionId);
      expect(result, isA<Err<RecordingId>>());
      expect((result as Err<RecordingId>).failure, isA<ProjectClosedFailure>());
    });

    test('rechaza con SessionNotInProgressFailure si la sesión está planeada o cerrada', () async {
      final useCase = build(
        snapshot: const SessionSnapshot(projectId: projectId, isInProgress: false),
      );
      final result = await useCase(sessionId);
      expect(result, isA<Err<RecordingId>>());
      expect((result as Err<RecordingId>).failure, isA<SessionNotInProgressFailure>());
    });

    test('rechaza con MicrophonePermissionDenied sin permiso', () async {
      audioRecorder.permissionGranted = false;
      final useCase = build();
      final result = await useCase(sessionId);
      expect(result, isA<Err<RecordingId>>());
      expect((result as Err<RecordingId>).failure, isA<MicrophonePermissionDenied>());
    });

    test('rechaza con RecordingAlreadyActiveFailure si ya hay una activa', () async {
      repository.active = Recording(
        id: const RecordingId('recording-0'),
        sessionId: sessionId,
        projectId: projectId,
        filePath: 'recordings/recording-0.wav',
        status: RecordingStatus.recording,
        durationMs: 0,
        sampleRate: 16000,
        channels: 1,
        startedAt: at,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = build();
      final result = await useCase(sessionId);
      expect(result, isA<Err<RecordingId>>());
      expect((result as Err<RecordingId>).failure, isA<RecordingAlreadyActiveFailure>());
    });

    test('inserta la grabación en estado recording cuando todo es válido', () async {
      final useCase = build();
      final result = await useCase(sessionId);
      expect(result, isA<Ok<RecordingId>>());
      final id = (result as Ok<RecordingId>).value;
      expect(repository.store[id.value]!.status, RecordingStatus.recording);
      expect(repository.store[id.value]!.sessionId, sessionId);
      expect(repository.store[id.value]!.projectId, projectId);
    });
  });

  group('StopRecording', () {
    test('fija duration_ms y stopped_at con lo que devuelve el escritor WAV', () async {
      final wavSink = _FakeWavSink()..durationToReturn = 45000;
      repository.store['recording-1'] = Recording(
        id: const RecordingId('recording-1'),
        sessionId: sessionId,
        projectId: projectId,
        filePath: 'recordings/recording-1.wav',
        status: RecordingStatus.recording,
        durationMs: 0,
        sampleRate: 16000,
        channels: 1,
        startedAt: at,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = StopRecording(repository, wavSink, Clock.fixed(at));
      final result = await useCase(const RecordingId('recording-1'));

      expect(result, isA<Ok<void>>());
      expect(wavSink.closed, isTrue);
      final stopped = repository.store['recording-1']!;
      expect(stopped.status, RecordingStatus.stopped);
      expect(stopped.durationMs, 45000);
      expect(stopped.stoppedAt, at);
    });
  });
}
