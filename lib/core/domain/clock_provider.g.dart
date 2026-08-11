// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reloj inyectable: en producción es el reloj del sistema, y en pruebas se
/// sobreescribe (p. ej. con `Clock.fixed(...)`) para que `created_at`,
/// `updated_at` y el orden de la bitácora sean deterministas.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// Reloj inyectable: en producción es el reloj del sistema, y en pruebas se
/// sobreescribe (p. ej. con `Clock.fixed(...)`) para que `created_at`,
/// `updated_at` y el orden de la bitácora sean deterministas.

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  /// Reloj inyectable: en producción es el reloj del sistema, y en pruebas se
  /// sobreescribe (p. ej. con `Clock.fixed(...)`) para que `created_at`,
  /// `updated_at` y el orden de la bitácora sean deterministas.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'30e71d378a201482bb785bc8babd9bfcb65538f7';
