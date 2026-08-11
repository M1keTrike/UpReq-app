import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Reloj inyectable: en producción es el reloj del sistema, y en pruebas se
/// sobreescribe (p. ej. con `Clock.fixed(...)`) para que `created_at`,
/// `updated_at` y el orden de la bitácora sean deterministas.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const Clock();
