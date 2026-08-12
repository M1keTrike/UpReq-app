import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  Transcript build({TranscriptStatus status = TranscriptStatus.done, String? text = 'Hola'}) {
    return Transcript(
      id: const TranscriptId('transcript-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      pass: TranscriptPass.finalPass,
      status: status,
      modelId: TranscriptionModel.small,
      text: text,
      failureReason: null,
      completedAt: at,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('TranscriptPass.dbValue/fromDbValue mapean final <-> finalPass', () {
    expect(TranscriptPass.finalPass.dbValue, 'final');
    expect(TranscriptPass.live.dbValue, 'live');
    expect(TranscriptPass.fromDbValue('final'), TranscriptPass.finalPass);
    expect(TranscriptPass.fromDbValue('live'), TranscriptPass.live);
  });

  test('dos transcripciones con los mismos campos son iguales y comparten hashCode', () {
    final a = build();
    final b = build();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('difieren si el texto difiere', () {
    expect(build(), isNot(build(text: 'Adiós')));
  });

  test('toString incluye id, pasada y estado', () {
    expect(build().toString(), 'Transcript(transcript-1, final, TranscriptStatus.done)');
  });

  test('copyWith sin argumentos conserva los valores; con argumentos los reemplaza', () {
    final original = build(status: TranscriptStatus.pending, text: null);

    expect(original.copyWith(), original);

    final changed = original.copyWith(
      status: TranscriptStatus.failed,
      failureReason: 'motor caído',
      completedAt: at.add(const Duration(seconds: 1)),
      updatedAt: at.add(const Duration(seconds: 1)),
    );
    expect(changed.status, TranscriptStatus.failed);
    expect(changed.failureReason, 'motor caído');
    expect(changed.completedAt, at.add(const Duration(seconds: 1)));
  });
}
