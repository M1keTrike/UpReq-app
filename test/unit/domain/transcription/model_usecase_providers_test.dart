import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/transcription/data/model_repository_impl.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/model_entry.dart';
import 'package:up_req/features/transcription/domain/usecases/cancel_model_download.dart';
import 'package:up_req/features/transcription/domain/usecases/watch_model_status.dart';

import '../../../support/fake_model_repository.dart';
import '../../../support/test_container.dart';

void main() {
  test('CancelModelDownload, resuelto vía provider, delega en el repositorio', () async {
    final modelRepository = FakeModelRepository();
    final container = buildTestContainer(
      overrides: [modelRepositoryProvider.overrideWithValue(modelRepository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(cancelModelDownloadProvider)(TranscriptionModel.small);

    expect(result, isA<Ok<void>>());
    expect(modelRepository.cancelled, isTrue);
    expect(modelRepository.lastCancelledModel, TranscriptionModel.small);
  });

  test('WatchModelStatus, resuelto vía provider, refleja qué modelos están disponibles', () async {
    final modelRepository = FakeModelRepository()..available.add(TranscriptionModel.base);
    final container = buildTestContainer(
      overrides: [modelRepositoryProvider.overrideWithValue(modelRepository)],
    );
    addTearDown(container.dispose);

    final status = await container.read(watchModelStatusProvider)().first;

    expect(status[TranscriptionModel.base], ModelStatus.available);
    expect(status[TranscriptionModel.small], ModelStatus.notDownloaded);
  });
}
