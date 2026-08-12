import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/model_entry.dart';

void main() {
  ModelEntry build({ModelStatus status = ModelStatus.downloading, double? progress = 0.5}) {
    return ModelEntry(
      model: TranscriptionModel.small,
      label: 'Definitiva',
      status: status,
      progress: progress,
      sizeBytes: 1000,
    );
  }

  test('dos entradas con los mismos campos son iguales y comparten hashCode', () {
    final a = build();
    final b = build();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('difieren si el progreso difiere', () {
    expect(build(), isNot(build(progress: 0.9)));
  });

  test('toString incluye el modelo, el estado y el progreso', () {
    expect(build().toString(), 'ModelEntry(TranscriptionModel.small, ModelStatus.downloading, progress: 0.5)');
  });
}
