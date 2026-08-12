import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/combine_latest.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/data/transcript_repository_impl.dart';
import 'package:up_req/features/transcription/domain/contracts/transcript_repository.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

import '../../data/just_audio_player.dart';
import '../contracts/audio_playback.dart';

part 'watch_active_segment.g.dart';

/// FR-019: cruza `position` del reproductor con las ventanas de los
/// segmentos y devuelve `null` fuera de todas. Sin temporizador propio: se
/// recalcula solo cuando cambia la posición o la lista de segmentos.
final class WatchActiveSegment {
  const WatchActiveSegment(this._transcriptRepository, this._audioPlayback);

  final TranscriptRepository _transcriptRepository;
  final AudioPlayback _audioPlayback;

  Stream<SegmentId?> call(TranscriptId id) {
    return combineLatest2<List<TranscriptSegment>, Duration, SegmentId?>(
      _transcriptRepository.watchSegments(id),
      _audioPlayback.position,
      (segments, position) {
        final ms = position.inMilliseconds;
        for (final segment in segments) {
          if (ms >= segment.fromMs && ms < segment.toMs) return segment.id;
        }
        return null;
      },
    ).distinct();
  }
}

@riverpod
WatchActiveSegment watchActiveSegment(Ref ref) {
  return WatchActiveSegment(ref.watch(transcriptRepositoryProvider), ref.watch(audioPlaybackProvider));
}
