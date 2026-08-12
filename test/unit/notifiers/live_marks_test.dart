import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/data/live_mark_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/live_mark_repository.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';
import 'package:up_req/features/recordings/presentation/live_marks_provider.dart';

import '../../support/test_container.dart';

class _FakeLiveMarkRepository implements LiveMarkRepository {
  List<LiveMark> marks = [];

  @override
  Stream<List<LiveMark>> watchByRecording(RecordingId id) => Stream.value(marks);

  @override
  Future<void> insert(LiveMark mark) => throw UnimplementedError();

  @override
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at) => throw UnimplementedError();

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) => throw UnimplementedError();
}

void main() {
  test('expone las marcas de una grabación a través de un único provider', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeLiveMarkRepository()
      ..marks = [
        LiveMark(
          id: const LiveMarkId('mark-1'),
          recordingId: const RecordingId('recording-1'),
          sessionId: const SessionId('session-1'),
          projectId: const ProjectId('project-1'),
          kind: LiveMarkKind.requirement,
          atMs: 1000,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [liveMarkRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(liveMarksProvider('recording-1'), (_, _) {});

    final marks = await container.read(liveMarksProvider('recording-1').future);
    expect(marks, hasLength(1));
    expect(marks.single.kind, LiveMarkKind.requirement);
  });

  test('sin marcas, el estado es una lista vacía', () async {
    final repository = _FakeLiveMarkRepository();
    final container = buildTestContainer(
      overrides: [liveMarkRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(liveMarksProvider('recording-1'), (_, _) {});

    final marks = await container.read(liveMarksProvider('recording-1').future);
    expect(marks, isEmpty);
  });
}
