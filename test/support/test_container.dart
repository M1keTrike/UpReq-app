import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';

/// Generador de identificadores con una secuencia fija (`id-0`, `id-1`, ...)
/// para que las pruebas puedan afirmar sobre los identificadores generados.
class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator({this.prefix = 'id'});

  final String prefix;
  int _next = 0;

  @override
  String generate() => '$prefix-${_next++}';
}

/// Contenedor de pruebas sobre `ProviderContainer.test()`. El reloj y el
/// generador de identificadores ya vienen sobreescritos por defecto para que
/// `created_at`, `updated_at` y los identificadores sean deterministas;
/// [overrides] añade los repositorios dobles y cualquier otro override que
/// necesite cada historia. `retry: (_, __) => null` desactiva el reintento
/// automático de Riverpod 3, que de lo contrario reintentaría indefinidamente
/// las pruebas del camino de error.
ProviderContainer buildTestContainer({
  List<Override> overrides = const [],
  DateTime? fixedNow,
  IdGenerator? idGeneratorOverride,
}) {
  return ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [
      clockProvider.overrideWithValue(
        Clock.fixed(fixedNow ?? DateTime.utc(2026, 1, 1)),
      ),
      idGeneratorProvider.overrideWithValue(
        idGeneratorOverride ?? SequentialIdGenerator(),
      ),
      ...overrides,
    ],
  );
}
