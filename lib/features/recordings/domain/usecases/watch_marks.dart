import 'package:up_req/core/domain/ids.dart';

import '../contracts/live_mark_repository.dart';
import '../entities/live_mark.dart';

/// Orden por `at_ms` (FR-008), delegado al repositorio.
final class WatchMarks {
  const WatchMarks(this._repository);

  final LiveMarkRepository _repository;

  Stream<List<LiveMark>> call(RecordingId id) => _repository.watchByRecording(id);
}
