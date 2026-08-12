// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_download_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Progreso de descarga por modelo, observado por `modelSettingsProvider`
/// (ui-contracts.md: "`progress` ... se observa por stream del
/// repositorio, no por la mutación"). `keepAlive`: si el analista sale de
/// ajustes a media descarga —`small` pesa cientos de MB (research.md)— la
/// descarga no debe morir por eso, mismo criterio que
/// `ActiveCaptureNotifier`.

@ProviderFor(ModelDownloadNotifier)
final modelDownloadProvider = ModelDownloadNotifierProvider._();

/// Progreso de descarga por modelo, observado por `modelSettingsProvider`
/// (ui-contracts.md: "`progress` ... se observa por stream del
/// repositorio, no por la mutación"). `keepAlive`: si el analista sale de
/// ajustes a media descarga —`small` pesa cientos de MB (research.md)— la
/// descarga no debe morir por eso, mismo criterio que
/// `ActiveCaptureNotifier`.
final class ModelDownloadNotifierProvider
    extends
        $NotifierProvider<
          ModelDownloadNotifier,
          Map<TranscriptionModel, DownloadProgress>
        > {
  /// Progreso de descarga por modelo, observado por `modelSettingsProvider`
  /// (ui-contracts.md: "`progress` ... se observa por stream del
  /// repositorio, no por la mutación"). `keepAlive`: si el analista sale de
  /// ajustes a media descarga —`small` pesa cientos de MB (research.md)— la
  /// descarga no debe morir por eso, mismo criterio que
  /// `ActiveCaptureNotifier`.
  ModelDownloadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadNotifierHash();

  @$internal
  @override
  ModelDownloadNotifier create() => ModelDownloadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<TranscriptionModel, DownloadProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<TranscriptionModel, DownloadProgress>>(value),
    );
  }
}

String _$modelDownloadNotifierHash() =>
    r'4de54e84d6c94a525fa09fcdeb8a25d2da4fb4b5';

/// Progreso de descarga por modelo, observado por `modelSettingsProvider`
/// (ui-contracts.md: "`progress` ... se observa por stream del
/// repositorio, no por la mutación"). `keepAlive`: si el analista sale de
/// ajustes a media descarga —`small` pesa cientos de MB (research.md)— la
/// descarga no debe morir por eso, mismo criterio que
/// `ActiveCaptureNotifier`.

abstract class _$ModelDownloadNotifier
    extends $Notifier<Map<TranscriptionModel, DownloadProgress>> {
  Map<TranscriptionModel, DownloadProgress> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<TranscriptionModel, DownloadProgress>,
              Map<TranscriptionModel, DownloadProgress>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<TranscriptionModel, DownloadProgress>,
                Map<TranscriptionModel, DownloadProgress>
              >,
              Map<TranscriptionModel, DownloadProgress>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
