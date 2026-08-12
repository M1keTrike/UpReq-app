import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/handle_storage_full.dart';

class _FakeRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};

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
  Future<Recording?> findById(RecordingId id) async => store[id.value];

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) =>
      throw UnimplementedError();

  @override
  Future<void> softDelete(RecordingId id, DateTime at) => throw UnimplementedError();
}

/// Simula que el escritor WAV ya cerró y parcheó la cabecera con lo
/// capturado antes de que el fallo de espacio se propagara (T038a: el fallo
/// se detecta en `append`, pero `closeAndFinalize` siempre puede recuperar
/// lo escrito hasta ese punto).
class _FakeWavSink implements WavSink {
  int partialDurationMs = 12500;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}

  @override
  Future<void> append(Uint8List pcmFrames) async {}

  @override
  Future<int> closeAndFinalize() async => partialDurationMs;

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    return partialDurationMs;
  }

  @override
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}
}

void main() {
  test(
    'cuando el escritor WAV falla por falta de espacio, la grabación pasa a stopped '
    'conservando el audio ya escrito y se devuelve StorageFullFailure',
    () async {
      final at = DateTime.utc(2026, 1, 1);
      final repository = _FakeRecordingRepository()
        ..store['recording-1'] = Recording(
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
      final wavSink = _FakeWavSink()..partialDurationMs = 12500;

      final useCase = HandleStorageFull(repository, wavSink, Clock.fixed(at));
      final result = await useCase(const RecordingId('recording-1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<StorageFullFailure>());

      final recording = repository.store['recording-1']!;
      expect(recording.status, RecordingStatus.stopped);
      // La cabecera se parcheó con lo capturado: la duración no es cero.
      expect(recording.durationMs, 12500);
      expect(recording.stoppedAt, at);
    },
  );
}
