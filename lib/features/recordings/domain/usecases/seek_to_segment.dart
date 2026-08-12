import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/transcription/data/transcript_repository_impl.dart';
import 'package:up_req/features/transcription/domain/contracts/transcript_repository.dart';

import '../../data/just_audio_player.dart';
import '../contracts/audio_playback.dart';

part 'seek_to_segment.g.dart';

/// FR-018: resuelve `from_ms` del segmento y salta a esa posición. El
/// segmento es de `transcription`; `recordings` lo consulta por contrato,
/// igual que ya hace `ActiveCaptureNotifier` con `Transcriber` (T083).
final class SeekToSegment {
  const SeekToSegment(this._transcriptRepository, this._audioPlayback);

  final TranscriptRepository _transcriptRepository;
  final AudioPlayback _audioPlayback;

  Future<Result<void>> call(SegmentId id) async {
    final segment = await _transcriptRepository.findSegmentById(id);
    if (segment == null) {
      return Err(NotFoundFailure('No se encontró el segmento $id.'));
    }
    await _audioPlayback.seek(Duration(milliseconds: segment.fromMs));
    return const Ok(null);
  }
}

@riverpod
SeekToSegment seekToSegment(Ref ref) {
  return SeekToSegment(ref.watch(transcriptRepositoryProvider), ref.watch(audioPlaybackProvider));
}
