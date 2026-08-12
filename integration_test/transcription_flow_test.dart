import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';

import '../test/support/fake_audio_playback.dart';
import '../test/support/fake_audio_recorder.dart';
import '../test/support/fake_model_repository.dart';
import '../test/support/fake_transcriber.dart';
import 'support/hardware_fakes.dart';
import 'support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await ensureVisible(tester, finder);
  await tester.tap(finder);
}

/// Crea un proyecto, una sesión llevada a "en curso" y una grabación
/// completa (con una trama de audio y detenida), lista para que la prueba
/// cierre la sesión y dispare la pasada definitiva.
Future<void> _recordAndStop(WidgetTester tester, FakeAudioRecorder recorder, {required String projectName}) async {
  await tester.tap(find.byTooltip('Nuevo proyecto'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Nombre'), projectName);
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Sesiones'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Nueva sesión'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Entrevista');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Entrevista'));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a En curso'));
  await tester.pumpAndSettle();

  await _tapVisible(tester, find.byKey(const Key('start-recording-button')));
  await tester.pumpAndSettle();
  recorder.emitFrame(Uint8List.fromList([1, 2, 3, 4]));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const Key('stop-recording-button')));
  await tester.pumpAndSettle();
}

/// T112 — validaciones V4 y V6 del quickstart (FR-013 a FR-016, FR-018,
/// FR-019), con `FakeTranscriber`: sin modelo, la transcripción queda
/// pendiente en vez de fallar; con modelo, produce segmentos y tocar uno
/// salta la reproducción al segundo exacto.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V4: sin modelo disponible, la transcripción queda pendiente', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();
    // FakeModelRepository() vacío por defecto: ningún modelo disponible.
    await pumpTestApp(tester, db, overrides: hardwareOverrides(audioRecorder: recorder));
    await tester.pumpAndSettle();

    await _recordAndStop(tester, recorder, projectName: 'Proyecto Sin Modelo');

    await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a Cerrada'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.textContaining('Grabación 00:'));
    await tester.pumpAndSettle();

    expect(find.text('Transcripción pendiente'), findsOneWidget);
    expect(find.text('La transcripción falló'), findsNothing);
  });

  testWidgets('V6: con modelo disponible, produce segmentos y saltar reproduce el segundo exacto', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();
    final transcriber = FakeTranscriber()
      ..segmentsToReturn = const [
        RawSegment(fromMs: 0, toMs: 2000, text: 'Hola'),
        RawSegment(fromMs: 2000, toMs: 4000, text: 'Adiós'),
      ];
    final modelRepository = FakeModelRepository()..available.add(TranscriptionModel.small);
    final audioPlayback = FakeAudioPlayback();

    await pumpTestApp(
      tester,
      db,
      overrides: hardwareOverrides(
        audioRecorder: recorder,
        transcriber: transcriber,
        modelRepository: modelRepository,
        audioPlayback: audioPlayback,
      ),
    );
    await tester.pumpAndSettle();

    await _recordAndStop(tester, recorder, projectName: 'Proyecto Con Modelo');

    await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a Cerrada'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.textContaining('Grabación 00:'));
    await tester.pumpAndSettle();

    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Adiós'), findsOneWidget);

    await tester.tap(find.text('Adiós'));
    await tester.pumpAndSettle();

    expect(audioPlayback.lastSeek, const Duration(milliseconds: 2000));
  });
}
