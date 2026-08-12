import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/model_entry.dart';
import 'package:up_req/features/transcription/presentation/model_settings_provider.dart';
import 'package:up_req/features/transcription/presentation/model_settings_screen.dart';

Future<void> _pump(WidgetTester tester, ModelSettingsState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [modelSettingsProvider.overrideWith((ref) => Stream.value(state))],
      child: const MaterialApp(home: ModelSettingsScreen()),
    ),
  );
}

void main() {
  testWidgets('sin Content-Length la barra es indeterminada y no se inventa un porcentaje', (tester) async {
    await _pump(
      tester,
      const ModelSettingsState(
        models: [
          ModelEntry(model: TranscriptionModel.base, label: 'En vivo', status: ModelStatus.notDownloaded),
          ModelEntry(
            model: TranscriptionModel.small,
            label: 'Definitiva',
            status: ModelStatus.downloading,
          ),
        ],
        pendingTranscripts: 0,
      ),
    );
    // Sin `pumpAndSettle`: una barra indeterminada anima en bucle y nunca
    // se asienta.
    await tester.pump();
    await tester.pump();

    final indicator = tester.widget<LinearProgressIndicator>(find.byKey(const Key('download-progress')));
    expect(indicator.value, isNull);
  });

  testWidgets('con Content-Length la barra refleja el progreso real', (tester) async {
    await _pump(
      tester,
      const ModelSettingsState(
        models: [
          ModelEntry(model: TranscriptionModel.base, label: 'En vivo', status: ModelStatus.notDownloaded),
          ModelEntry(
            model: TranscriptionModel.small,
            label: 'Definitiva',
            status: ModelStatus.downloading,
            progress: 0.5,
          ),
        ],
        pendingTranscripts: 0,
      ),
    );
    await tester.pumpAndSettle();

    final indicator = tester.widget<LinearProgressIndicator>(find.byKey(const Key('download-progress')));
    expect(indicator.value, 0.5);
  });

  testWidgets('modelo disponible muestra su estado y no ofrece descargar', (tester) async {
    await _pump(
      tester,
      const ModelSettingsState(
        models: [
          ModelEntry(model: TranscriptionModel.base, label: 'En vivo', status: ModelStatus.available),
          ModelEntry(model: TranscriptionModel.small, label: 'Definitiva', status: ModelStatus.notDownloaded),
        ],
        pendingTranscripts: 3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.byKey(const Key('download-model-base')), findsNothing);
    expect(find.byKey(const Key('download-model-small')), findsOneWidget);
    expect(find.byKey(const Key('pending-transcripts-count')), findsOneWidget);
  });
}
