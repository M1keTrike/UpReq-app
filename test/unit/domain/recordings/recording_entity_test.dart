import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  Recording build({DateTime? stoppedAt}) {
    return Recording(
      id: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      filePath: 'recordings/recording-1.wav',
      status: RecordingStatus.stopped,
      durationMs: 5000,
      sampleRate: 16000,
      channels: 1,
      startedAt: at,
      stoppedAt: stoppedAt ?? at,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('dos grabaciones con los mismos campos son iguales y comparten hashCode', () {
    final a = build();
    final b = build();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('difieren si algún campo difiere', () {
    expect(build(), isNot(build(stoppedAt: at.add(const Duration(seconds: 1)))));
  });

  test('toString incluye id, estado y duración', () {
    expect(build().toString(), 'Recording(recording-1, RecordingStatus.stopped, 5000ms)');
  });

  test('copyWith sin argumentos conserva los valores; con argumentos los reemplaza', () {
    final original = build();

    final unchanged = original.copyWith();
    expect(unchanged, original);

    final changed = original.copyWith(
      status: RecordingStatus.interrupted,
      durationMs: 9000,
      stoppedAt: at.add(const Duration(minutes: 1)),
      updatedAt: at.add(const Duration(minutes: 1)),
    );
    expect(changed.status, RecordingStatus.interrupted);
    expect(changed.durationMs, 9000);
    expect(changed.stoppedAt, at.add(const Duration(minutes: 1)));
    expect(changed.updatedAt, at.add(const Duration(minutes: 1)));
    // Los campos no expuestos por copyWith se conservan tal cual.
    expect(changed.id, original.id);
    expect(changed.filePath, original.filePath);
  });
}
