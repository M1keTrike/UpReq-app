// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_capture_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Primera excepción real a `autoDispose` del proyecto (constitución,
/// Principio I). Justificación: este notifier posee el flujo PCM, el
/// escritor WAV y (desde US4) la sesión de transcripción en vivo. Con
/// `autoDispose`, navegar del detalle de sesión a otra pantalla a media
/// entrevista destruiría el provider y con él la grabación en curso — un
/// analista perdiendo una entrevista por haber consultado el glosario es
/// exactamente el modo de falla que este incremento existe para evitar. Se
/// libera de forma explícita al detener o al recuperar, no por ciclo de vida
/// de pantalla.

@ProviderFor(ActiveCaptureNotifier)
final activeCaptureProvider = ActiveCaptureNotifierProvider._();

/// Primera excepción real a `autoDispose` del proyecto (constitución,
/// Principio I). Justificación: este notifier posee el flujo PCM, el
/// escritor WAV y (desde US4) la sesión de transcripción en vivo. Con
/// `autoDispose`, navegar del detalle de sesión a otra pantalla a media
/// entrevista destruiría el provider y con él la grabación en curso — un
/// analista perdiendo una entrevista por haber consultado el glosario es
/// exactamente el modo de falla que este incremento existe para evitar. Se
/// libera de forma explícita al detener o al recuperar, no por ciclo de vida
/// de pantalla.
final class ActiveCaptureNotifierProvider
    extends $NotifierProvider<ActiveCaptureNotifier, ActiveCapture?> {
  /// Primera excepción real a `autoDispose` del proyecto (constitución,
  /// Principio I). Justificación: este notifier posee el flujo PCM, el
  /// escritor WAV y (desde US4) la sesión de transcripción en vivo. Con
  /// `autoDispose`, navegar del detalle de sesión a otra pantalla a media
  /// entrevista destruiría el provider y con él la grabación en curso — un
  /// analista perdiendo una entrevista por haber consultado el glosario es
  /// exactamente el modo de falla que este incremento existe para evitar. Se
  /// libera de forma explícita al detener o al recuperar, no por ciclo de vida
  /// de pantalla.
  ActiveCaptureNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCaptureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCaptureNotifierHash();

  @$internal
  @override
  ActiveCaptureNotifier create() => ActiveCaptureNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveCapture? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveCapture?>(value),
    );
  }
}

String _$activeCaptureNotifierHash() =>
    r'e86c2fa74e144a5edadd0c9ad7ce78e803b1dee2';

/// Primera excepción real a `autoDispose` del proyecto (constitución,
/// Principio I). Justificación: este notifier posee el flujo PCM, el
/// escritor WAV y (desde US4) la sesión de transcripción en vivo. Con
/// `autoDispose`, navegar del detalle de sesión a otra pantalla a media
/// entrevista destruiría el provider y con él la grabación en curso — un
/// analista perdiendo una entrevista por haber consultado el glosario es
/// exactamente el modo de falla que este incremento existe para evitar. Se
/// libera de forma explícita al detener o al recuperar, no por ciclo de vida
/// de pantalla.

abstract class _$ActiveCaptureNotifier extends $Notifier<ActiveCapture?> {
  ActiveCapture? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ActiveCapture?, ActiveCapture?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveCapture?, ActiveCapture?>,
              ActiveCapture?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
