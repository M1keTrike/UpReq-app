import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/transcript_repository_impl.dart';
import '../contracts/transcript_repository.dart';
import 'run_final_pass.dart';

part 'process_pending_transcripts.g.dart';

/// Cola de FR-016: recorre `findPending()` y lanza la pasada definitiva de
/// cada una. Se ejecuta tras completarse una descarga (`DownloadModel`), que
/// es el único momento en que una transcripción `pending` puede dejar de
/// estarlo sin que el analista vuelva a cerrar cada sesión a mano.
final class ProcessPendingTranscripts {
  const ProcessPendingTranscripts(this._transcriptRepository, this._runFinalPass);

  final TranscriptRepository _transcriptRepository;
  final RunFinalPass _runFinalPass;

  Future<Result<int>> call() async {
    final pending = await _transcriptRepository.findPending();
    var processed = 0;
    for (final transcript in pending) {
      final result = await _runFinalPass(transcript.recordingId);
      if (result is Ok) processed++;
    }
    return Ok(processed);
  }
}

// keepAlive: se lee desde DownloadModel (T103) y, en presentación, desde
// ModelDownloadNotifier (keepAlive). Mismo criterio que run_final_pass.dart.
@Riverpod(keepAlive: true)
ProcessPendingTranscripts processPendingTranscripts(Ref ref) {
  return ProcessPendingTranscripts(ref.watch(transcriptRepositoryProvider), ref.watch(runFinalPassProvider));
}
