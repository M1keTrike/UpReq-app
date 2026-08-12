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

const _withPartial = ActiveCapture(
  id: RecordingId('recording-1'),
  elapsed: Duration(seconds: 10),
  marksPlaced: 0,
  isInterrupted: false,
  livePartial: 'y entonces el usuario dijo que',
);

const _withoutPartial = ActiveCapture(
  id: RecordingId('recording-1'),
  elapsed: Duration(seconds: 10),
  marksPlaced: 0,
  isInterrupted: false,
);

void main() {
  testWidgets('la zona aparece con livePartial no nulo', (tester) async {
    await _pump(tester, _withPartial);
    await tester.pump();

    expect(find.byKey(const Key('live-partial-zone')), findsOneWidget);
    expect(find.text('y entonces el usuario dijo que'), findsOneWidget);
  });

  testWidgets('la zona desaparece por completo cuando livePartial es null', (tester) async {
    await _pump(tester, _withoutPartial);
    await tester.pump();

    expect(find.byKey(const Key('live-partial-zone')), findsNothing);
  });

  testWidgets('los tres botones de marcado siguen visibles con o sin pasada en vivo', (tester) async {
    await _pump(tester, _withPartial);
    await tester.pump();
    expect(find.byKey(const Key('mark-button-requirement')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-doubt')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-quote')), findsOneWidget);

    await _pump(tester, _withoutPartial);
    await tester.pump();
    expect(find.byKey(const Key('mark-button-requirement')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-doubt')), findsOneWidget);
    expect(find.byKey(const Key('mark-button-quote')), findsOneWidget);
  });

  testWidgets('el texto de la pasada en vivo no es seleccionable ni tocable', (tester) async {
    await _pump(tester, _withPartial);
    await tester.pump();

    expect(find.byType(SelectableText), findsNothing);
    final ignorePointers = tester.widgetList<IgnorePointer>(
      find.ancestor(
        of: find.text('y entonces el usuario dijo que'),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignorePointers.any((widget) => widget.ignoring), isTrue);
  });
}
