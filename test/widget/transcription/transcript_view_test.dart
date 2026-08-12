import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/data/transcript_repository_impl.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';
import 'package:up_req/features/transcription/presentation/transcript_section.dart';

import '../../support/fake_transcript_repository.dart';

final _at = DateTime.utc(2026, 1, 1);
const _recordingId = RecordingId('recording-1');

Future<void> _pump(WidgetTester tester, FakeTranscriptRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transcriptRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: Scaffold(body: TranscriptSection(recordingId: 'recording-1')),
      ),
    ),
  );
}

void main() {
  testWidgets('TranscriptPending se presenta como aviso con acción hacia ajustes, nunca como error', (
    tester,
  ) async {
    final repository = FakeTranscriptRepository();
    await repository.upsert(
      Transcript(
        id: const TranscriptId('transcript-1'),
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.pending,
        modelId: TranscriptionModel.small,
        createdAt: _at,
        updatedAt: _at,
      ),
    );

    await _pump(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('Transcripción pendiente'), findsOneWidget);
    expect(find.text('Ir a ajustes'), findsOneWidget);
    expect(find.textContaining('error', findRichText: true), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('TranscriptRunning muestra que la pasada está en curso', (tester) async {
    final repository = FakeTranscriptRepository();
    await repository.upsert(
      Transcript(
        id: const TranscriptId('transcript-1'),
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.processing,
        modelId: TranscriptionModel.small,
        createdAt: _at,
        updatedAt: _at,
      ),
    );

    await _pump(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('Transcribiendo...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TranscriptReady lista los segmentos con su instante de inicio', (tester) async {
    final repository = FakeTranscriptRepository();
    const id = TranscriptId('transcript-1');
    await repository.upsert(
      Transcript(
        id: id,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.done,
        modelId: TranscriptionModel.small,
        text: 'Hola buenas tardes',
        completedAt: _at,
        createdAt: _at,
        updatedAt: _at,
      ),
    );
    await repository.replaceSegments(id, [
      TranscriptSegment(
        id: const SegmentId('segment-1'),
        transcriptId: id,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        fromMs: 0,
        toMs: 1000,
        position: 0,
        text: 'Hola',
        createdAt: _at,
        updatedAt: _at,
      ),
    ]);

    await _pump(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('TranscriptFailed muestra el motivo del fallo', (tester) async {
    final repository = FakeTranscriptRepository();
    await repository.upsert(
      Transcript(
        id: const TranscriptId('transcript-1'),
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.failed,
        modelId: TranscriptionModel.small,
        failureReason: 'motor nativo caído',
        createdAt: _at,
        updatedAt: _at,
      ),
    );

    await _pump(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('La transcripción falló'), findsOneWidget);
    expect(find.text('motor nativo caído'), findsOneWidget);
  });
}
