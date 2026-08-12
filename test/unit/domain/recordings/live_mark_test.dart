import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/contracts/live_mark_repository.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/domain/usecases/change_mark_kind.dart';
import 'package:up_req/features/recordings/domain/usecases/place_live_mark.dart';

class _FakeLiveMarkRepository implements LiveMarkRepository {
  final Map<String, LiveMark> store = {};

  @override
  Future<void> insert(LiveMark mark) async => store[mark.id.value] = mark;

  @override
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(kind: kind, updatedAt: at);
  }

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) async => store.remove(id.value);

  @override
  Stream<List<LiveMark>> watchByRecording(RecordingId id) => throw UnimplementedError();
}

class _FakeRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};

  @override
  Future<Recording?> findById(RecordingId id) async => store[id.value];

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
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) => throw UnimplementedError();

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) =>
      throw UnimplementedError();

  @override
  Future<void> softDelete(RecordingId id, DateTime at) => throw UnimplementedError();
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);
  final String _id;
  @override
  String generate() => _id;
}

void main() {
  final startedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
  const recordingId = RecordingId('recording-1');

  late _FakeLiveMarkRepository liveMarkRepository;
  late _FakeRecordingRepository recordingRepository;

  setUp(() {
    liveMarkRepository = _FakeLiveMarkRepository();
    recordingRepository = _FakeRecordingRepository();
  });

  group('PlaceLiveMark', () {
    test('rechaza con NoActiveRecordingFailure sin captura activa', () async {
      final useCase = PlaceLiveMark(
        liveMarkRepository,
        recordingRepository,
        _FixedIdGenerator('mark-1'),
        Clock.fixed(startedAt.add(const Duration(seconds: 30))),
      );

      final result = await useCase(recordingId, LiveMarkKind.requirement);
      expect(result, isA<Err<LiveMarkId>>());
      expect((result as Err<LiveMarkId>).failure, isA<NoActiveRecordingFailure>());
    });

    test('calcula at_ms desde el inicio de su grabación', () async {
      recordingRepository.store['recording-1'] = Recording(
        id: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        filePath: 'recordings/recording-1.wav',
        status: RecordingStatus.recording,
        durationMs: 0,
        sampleRate: 16000,
        channels: 1,
        startedAt: startedAt,
        createdAt: startedAt,
        updatedAt: startedAt,
      );

      final useCase = PlaceLiveMark(
        liveMarkRepository,
        recordingRepository,
        _FixedIdGenerator('mark-1'),
        Clock.fixed(startedAt.add(const Duration(seconds: 30))),
      );

      final result = await useCase(recordingId, LiveMarkKind.doubt);
      expect(result, isA<Ok<LiveMarkId>>());
      final mark = liveMarkRepository.store['mark-1']!;
      expect(mark.atMs, 30000);
      expect(mark.kind, LiveMarkKind.doubt);
    });

    test('admite dos marcas en el mismo instante sin deduplicar', () async {
      recordingRepository.store['recording-1'] = Recording(
        id: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        filePath: 'recordings/recording-1.wav',
        status: RecordingStatus.recording,
        durationMs: 0,
        sampleRate: 16000,
        channels: 1,
        startedAt: startedAt,
        createdAt: startedAt,
        updatedAt: startedAt,
      );
      final fixedNow = Clock.fixed(startedAt.add(const Duration(seconds: 10)));

      final first = await PlaceLiveMark(
        liveMarkRepository,
        recordingRepository,
        _FixedIdGenerator('mark-1'),
        fixedNow,
      )(recordingId, LiveMarkKind.quote);
      final second = await PlaceLiveMark(
        liveMarkRepository,
        recordingRepository,
        _FixedIdGenerator('mark-2'),
        fixedNow,
      )(recordingId, LiveMarkKind.quote);

      expect(first, isA<Ok<LiveMarkId>>());
      expect(second, isA<Ok<LiveMarkId>>());
      expect(liveMarkRepository.store, hasLength(2));
      expect(liveMarkRepository.store['mark-1']!.atMs, liveMarkRepository.store['mark-2']!.atMs);
    });
  });

  group('ChangeMarkKind', () {
    test('funciona con la grabación ya detenida', () async {
      final at = DateTime.utc(2026, 1, 1);
      liveMarkRepository.store['mark-1'] = LiveMark(
        id: const LiveMarkId('mark-1'),
        recordingId: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        kind: LiveMarkKind.requirement,
        atMs: 1000,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = ChangeMarkKind(liveMarkRepository, Clock.fixed(at));
      final result = await useCase(const LiveMarkId('mark-1'), LiveMarkKind.quote);

      expect(result, isA<Ok<void>>());
      expect(liveMarkRepository.store['mark-1']!.kind, LiveMarkKind.quote);
    });
  });
}
