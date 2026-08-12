import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/model_repository_impl.dart';
import '../contracts/model_repository.dart';
import '../contracts/transcriber.dart';

part 'cancel_model_download.g.dart';

/// FR-022: cancela una descarga en curso. `ModelDownloadClient` (T101) es
/// quien garantiza que el `.part` no sobrevive a la cancelación.
final class CancelModelDownload {
  const CancelModelDownload(this._repository);

  final ModelRepository _repository;

  Future<Result<void>> call(TranscriptionModel model) async {
    await _repository.cancelDownload(model);
    return const Ok(null);
  }
}

@riverpod
CancelModelDownload cancelModelDownload(Ref ref) => CancelModelDownload(ref.watch(modelRepositoryProvider));
