import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/recordings/data/just_audio_player.dart';
import 'package:up_req/features/recordings/data/live_mark_repository_impl.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/live_mark_repository.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/recording_detail_screen.dart';
import 'package:up_req/features/transcription/data/transcript_repository_impl.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

import '../../support/fake_audio_playback.dart';
import '../../support/fake_recording_repository.dart';
import '../../support/fake_transcript_repository.dart';

class _FakeLiveMarkRepository implements LiveMarkRepository {
  @override
  Stream<List<LiveMark>> watchByRecording(RecordingId id) => Stream.value(const []);

  @override
  Future<void> insert(LiveMark mark) async {}

  @override
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at) async {}

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) async {}
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

final _at = DateTime.utc(2026, 1, 1);
const _recordingId = RecordingId('recording-1');

Recording _recording() => Recording(
      id: _recordingId,
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      filePath: 'recordings/recording-1.wav',
      status: RecordingStatus.stopped,
      durationMs: 4000,
      sampleRate: 16000,
      channels: 1,
      startedAt: _at,
      stoppedAt: _at,
      createdAt: _at,
      updatedAt: _at,
    );

Future<FakeAudioPlayback> _pump(
  WidgetTester tester, {
  required FakeTranscriptRepository transcriptRepository,
}) async {
  final recordingRepository = FakeRecordingRepository()..store['recording-1'] = _recording();
  final playback = FakeAudioPlayback();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingRepositoryProvider.overrideWithValue(recordingRepository),
        liveMarkRepositoryProvider.overrideWithValue(_FakeLiveMarkRepository()),
        transcriptRepositoryProvider.overrideWithValue(transcriptRepository),
        audioPlaybackProvider.overrideWithValue(playback),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
      ],
      child: const MaterialApp(
        home: RecordingDetailScreen(recordingId: 'recording-1'),
      ),
    ),
  );
  return playback;
}

void main() {
  testWidgets('el reproductor funciona sin transcripción (FR-017)', (tester) async {
    await _pump(tester, transcriptRepository: FakeTranscriptRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playback-toggle-button')), findsOneWidget);
    expect(find.text('Transcripción pendiente'), findsOneWidget);
  });

  testWidgets('el segmento activo se resalta conforme avanza la posición', (tester) async {
    final transcriptRepository = FakeTranscriptRepository();
    const transcriptId = TranscriptId('transcript-1');
    await transcriptRepository.upsert(
      Transcript(
        id: transcriptId,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.done,
        modelId: TranscriptionModel.small,
        text: 'Hola. Adiós.',
        completedAt: _at,
        createdAt: _at,
        updatedAt: _at,
      ),
    );
    await transcriptRepository.replaceSegments(transcriptId, [
      TranscriptSegment(
        id: const SegmentId('segment-1'),
        transcriptId: transcriptId,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        fromMs: 0,
        toMs: 2000,
        position: 0,
        text: 'Hola',
        createdAt: _at,
        updatedAt: _at,
      ),
      TranscriptSegment(
        id: const SegmentId('segment-2'),
        transcriptId: transcriptId,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        fromMs: 2000,
        toMs: 4000,
        position: 1,
        text: 'Adiós',
        createdAt: _at,
        updatedAt: _at,
      ),
    ]);

    final playback = await _pump(tester, transcriptRepository: transcriptRepository);
    await tester.pumpAndSettle();

    playback.emitPosition(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ListTile>(find.byKey(const Key('segment-segment-1'))).selected,
      isTrue,
    );
    expect(
      tester.widget<ListTile>(find.byKey(const Key('segment-segment-2'))).selected,
      isFalse,
    );

    playback.emitPosition(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ListTile>(find.byKey(const Key('segment-segment-1'))).selected,
      isFalse,
    );
    expect(
      tester.widget<ListTile>(find.byKey(const Key('segment-segment-2'))).selected,
      isTrue,
    );
  });

  testWidgets(
    'tocar reproducir cambia el icono a pausa de inmediato, sin esperar a que termine el audio',
    (tester) async {
      final playback = await _pump(tester, transcriptRepository: FakeTranscriptRepository());
      await tester.pumpAndSettle();
      // `just_audio.play()` real no resuelve hasta que la reproducción se
      // pausa o termina; este gate nunca se completa en la prueba, así que
      // si el icono cambia igual, es porque el notifier no lo espera.
      playback.playGate = Completer<void>();

      await tester.tap(find.byKey(const Key('playback-toggle-button')));
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    },
  );

  testWidgets('al terminar sola la reproducción, rebobina y permite repetir', (tester) async {
    final playback = await _pump(tester, transcriptRepository: FakeTranscriptRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('playback-toggle-button')));
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    playback.emitPosition(const Duration(milliseconds: 4000));
    playback.emitCompleted();
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(playback.lastSeek, Duration.zero);
    // Debe pausar antes de rebobinar: si el rebobinado llegara con
    // `playing` aún en `true`, un `just_audio` real reanudaría solo desde
    // el segundo 0 en vez de esperar a que el usuario toque "reproducir".
    expect(playback.playing, isFalse);
  });
}
