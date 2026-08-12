import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/live_mark_repository_impl.dart';
import '../domain/entities/live_mark.dart';
import '../domain/usecases/watch_marks.dart';

part 'live_marks_provider.g.dart';

/// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
/// lista del detalle de grabación (US5) y, indirectamente, el contador de
/// `ActiveCapture.marksPlaced` durante la captura.
@riverpod
Stream<List<LiveMark>> liveMarks(Ref ref, String recordingId) {
  final repository = ref.watch(liveMarkRepositoryProvider);
  return WatchMarks(repository)(RecordingId(recordingId));
}
