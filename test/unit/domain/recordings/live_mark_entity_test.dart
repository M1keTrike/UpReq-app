import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  LiveMark build({LiveMarkKind kind = LiveMarkKind.requirement}) {
    return LiveMark(
      id: const LiveMarkId('mark-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      kind: kind,
      atMs: 1500,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('dos marcas con los mismos campos son iguales y comparten hashCode', () {
    final a = build();
    final b = build();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('difieren si el tipo difiere', () {
    expect(build(), isNot(build(kind: LiveMarkKind.doubt)));
  });

  test('toString incluye id, tipo e instante', () {
    expect(build().toString(), 'LiveMark(mark-1, LiveMarkKind.requirement, 1500ms)');
  });

  test('copyWith sin argumentos conserva los valores; con argumentos los reemplaza', () {
    final original = build();

    expect(original.copyWith(), original);

    final changed = original.copyWith(kind: LiveMarkKind.quote, updatedAt: at.add(const Duration(seconds: 1)));
    expect(changed.kind, LiveMarkKind.quote);
    expect(changed.updatedAt, at.add(const Duration(seconds: 1)));
    expect(changed.atMs, original.atMs);
  });
}
