import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

Widget _pumpWith(AsyncValue<String> value) {
  return MaterialApp(
    home: Scaffold(
      body: AsyncScaffoldBody<String>(
        value: value,
        isEmpty: (v) => v.isEmpty,
        empty: (_) => const Text('vacío'),
        data: (context, v) => Text(v),
      ),
    ),
  );
}

/// Cambiar `trigger` fuerza que `watched` se reconstruya entero (no solo
/// reemita): exactamente el mecanismo real de `modelSettingsProvider`
/// reconstruyéndose por `ref.watch(modelDownloadProvider)` en cada tick de
/// progreso. Un `StreamNotifier` normal (sin codegen) pasa por el mismo
/// `ProviderElement.asyncTransition` interno que el resto de la app.
class _TriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final _trigger = NotifierProvider<_TriggerNotifier, int>(_TriggerNotifier.new);

class _WatchedNotifier extends StreamNotifier<String> {
  @override
  Stream<String> build() {
    final n = ref.watch(_trigger);
    return Stream.value('valor $n');
  }
}

final _watched = StreamNotifierProvider<_WatchedNotifier, String>(_WatchedNotifier.new);

void main() {
  testWidgets(
    'un provider que se reconstruye por un ref.watch que cambia seguido no parpadea a un spinner '
    '(bug real: ajustes de modelo durante una descarga alternaba entre spinner y contenido)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => AsyncScaffoldBody<String>(
                  value: ref.watch(_watched),
                  isEmpty: (_) => false,
                  empty: (_) => const SizedBox.shrink(),
                  data: (context, v) => Text(v),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('valor 0'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final element = tester.element(find.byType(Consumer));
      final container = ProviderScope.containerOf(element);
      // Dispara la reconstrucción completa de `_watched`. `Stream.value`
      // tampoco emite de forma síncrona, así que hay un hueco real de un
      // microtask antes del próximo dato — el mismo hueco donde el bug
      // mostraba el spinner.
      container.read(_trigger.notifier).increment();
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'debe seguir mostrando el valor previo mientras se resuelve el nuevo, no un spinner',
      );

      await tester.pumpAndSettle();
      expect(find.text('valor 1'), findsOneWidget);
    },
  );

  testWidgets('AsyncLoading sin valor previo (carga en frío) sí muestra el spinner', (tester) async {
    await tester.pumpWidget(_pumpWith(const AsyncLoading<String>()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AsyncData normal muestra los datos', (tester) async {
    await tester.pumpWidget(_pumpWith(const AsyncData('hola')));

    expect(find.text('hola'), findsOneWidget);
  });

  testWidgets('AsyncError sin valor previo muestra el error, no queda afectado por el fix', (tester) async {
    await tester.pumpWidget(_pumpWith(AsyncError<String>('boom', StackTrace.empty)));

    expect(find.textContaining('boom'), findsOneWidget);
  });
}
