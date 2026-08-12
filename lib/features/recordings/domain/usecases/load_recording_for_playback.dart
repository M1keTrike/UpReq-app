import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/just_audio_player.dart';
import '../../data/recording_repository_impl.dart';
import '../contracts/audio_playback.dart';
import '../contracts/recording_repository.dart';

part 'load_recording_for_playback.g.dart';

/// FR-017: el reproductor funciona exista o no transcripción. Resuelve la
/// grabación y carga su archivo, sin mirar en ningún momento si hay
/// transcripción.
final class LoadRecordingForPlayback {
  const LoadRecordingForPlayback(this._recordingRepository, this._audioPlayback);

  final RecordingRepository _recordingRepository;
  final AudioPlayback _audioPlayback;

  Future<Result<void>> call(RecordingId id) async {
    final recording = await _recordingRepository.findById(id);
    if (recording == null) {
      return Err(NotFoundFailure('No se encontró la grabación $id.'));
    }
    await _audioPlayback.load(recording.filePath);
    return const Ok(null);
  }
}

@riverpod
LoadRecordingForPlayback loadRecordingForPlayback(Ref ref) {
  return LoadRecordingForPlayback(
    ref.watch(recordingRepositoryProvider),
    ref.watch(audioPlaybackProvider),
  );
}
