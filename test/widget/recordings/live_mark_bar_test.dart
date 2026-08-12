import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/recordings/presentation/live_mark_bar.dart';

Future<void> _pump(WidgetTester tester, ActiveCapture? active) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: LiveMarkBar(active: active))),
    ),
  );
}

const _active = ActiveCapture(
  id: RecordingId('recording-1'),
  elapsed: Duration(seconds: 10),
  marksPlaced: 0,
  isInterrupted: false,
);

const _interrupted = ActiveCapture(
  id: RecordingId('recording-1'),
  elapsed: Duration(seconds: 10),
  marksPlaced: 0,
  isInterrupted: true,
);

void main() {
  testWidgets('los tres controles solo están visibles con captura activa y no interrumpida', (
    tester,
  ) async {
    await _pump(tester, null);
    await tester.pump();
    expect(find.byKey(const Key('mark-button-requirement')), findsNothing);
    expect(find.byKey(const Key('mark-button-doubt')), findsNothing);
    expect(find.byKey(const Key('mark-button-quote')), findsNothing);

    await _pump(tester, _interrupted);
    await tester.pump();
    expect(find.byKey(const Key('mark-button-requirement')), findsNothing);

    await _pump(tester, _active);
    await tester.pump();
    expect(find.byKey(const Key('mark-button-requirement')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-doubt')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-quote')), findsOneWidget);
  });

  testWidgets('tocar un botón no abre ningún diálogo', (tester) async {
    await _pump(tester, _active);
    await tester.pump();

    await tester.tap(find.byKey(const Key('mark-button-requirement')));
    await tester.pump();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
