import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/recording_repository_impl.dart';
import '../domain/entities/recording.dart';

part 'recording_detail_provider.g.dart';

/// `recordingDetailProvider(recordingId)` de ui-contracts.md, pantalla 3.
/// Deliberadamente delgado: marcas (`LiveMarkList`), transcripción
/// (`TranscriptSection`) y reproducción (`RecordingPlaybackNotifier`) son
/// secciones autocontenidas con su propio provider, el mismo criterio con
/// el que `SessionDetailState` no incluye la captura (`SessionCaptureSection`
/// se basta sola).
final class RecordingDetailState {
  const RecordingDetailState({required this.recording, required this.isReadOnly});

  final Recording recording;

  /// Deriva de `ProjectStatusReader.isActive`, igual que
  /// `SessionDetailState.isReadOnly`: proyecto cerrado ⇒ solo lectura.
  final bool isReadOnly;
}

@riverpod
Stream<RecordingDetailState> recordingDetail(Ref ref, String recordingId) {
  final id = RecordingId(recordingId);
  final recordingRepository = ref.watch(recordingRepositoryProvider);
  final statusReader = ref.watch(projectStatusReaderProvider);

  return recordingRepository.watchById(id).asyncMap((recording) async {
    if (recording == null) {
      throw NotFoundFailure('No se encontró la grabación $recordingId.');
    }
    final isActive = await statusReader.isActive(recording.projectId);
    return RecordingDetailState(recording: recording, isReadOnly: !isActive);
  });
}
