import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/data/live_mark_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/live_mark_repository.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';
import 'package:up_req/features/recordings/presentation/live_mark_list.dart';

class _FakeLiveMarkRepository implements LiveMarkRepository {
  final _marks = <LiveMark>[];
  final updateKindCalls = <(LiveMarkId, LiveMarkKind)>[];
  final softDeleteCalls = <LiveMarkId>[];

  @override
  Stream<List<LiveMark>> watchByRecording(RecordingId id) => Stream.value(_marks);

  @override
  Future<void> insert(LiveMark mark) async => _marks.add(mark);

  @override
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at) async {
    updateKindCalls.add((id, kind));
  }

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) async {
    softDeleteCalls.add(id);
  }
}

final _at = DateTime.utc(2026, 1, 1);
const _recordingId = RecordingId('recording-1');

LiveMark _mark(String id, LiveMarkKind kind) => LiveMark(
      id: LiveMarkId(id),
      recordingId: _recordingId,
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      kind: kind,
      atMs: 1000,
      createdAt: _at,
      updatedAt: _at,
    );

Future<_FakeLiveMarkRepository> _pump(WidgetTester tester, {required bool isReadOnly}) async {
  final repository = _FakeLiveMarkRepository()..insert(_mark('mark-1', LiveMarkKind.doubt));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [liveMarkRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: LiveMarkList(recordingId: _recordingId, isReadOnly: isReadOnly),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('ofrece cambiar el tipo y eliminar la marca cuando no es solo lectura', (tester) async {
    final repository = await _pump(tester, isReadOnly: false);

    expect(find.byKey(const Key('mark-kind-menu-mark-1')), findsOneWidget);
    expect(find.byKey(const Key('mark-delete-mark-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-kind-menu-mark-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Posible requisito').last);
    await tester.pumpAndSettle();

    expect(repository.updateKindCalls, [(const LiveMarkId('mark-1'), LiveMarkKind.requirement)]);

    await tester.tap(find.byKey(const Key('mark-delete-mark-1')));
    await tester.pumpAndSettle();

    expect(repository.softDeleteCalls, [const LiveMarkId('mark-1')]);
  });

  testWidgets('no ofrece cambiar tipo ni eliminar en solo lectura', (tester) async {
    await _pump(tester, isReadOnly: true);

    expect(find.byKey(const Key('mark-kind-menu-mark-1')), findsNothing);
    expect(find.byKey(const Key('mark-delete-mark-1')), findsNothing);
  });
}
