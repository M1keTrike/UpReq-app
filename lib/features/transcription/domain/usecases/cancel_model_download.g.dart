// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_model_download.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cancelModelDownload)
final cancelModelDownloadProvider = CancelModelDownloadProvider._();

final class CancelModelDownloadProvider
    extends
        $FunctionalProvider<
          CancelModelDownload,
          CancelModelDownload,
          CancelModelDownload
        >
    with $Provider<CancelModelDownload> {
  CancelModelDownloadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cancelModelDownloadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cancelModelDownloadHash();

  @$internal
  @override
  $ProviderElement<CancelModelDownload> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CancelModelDownload create(Ref ref) {
    return cancelModelDownload(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CancelModelDownload value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CancelModelDownload>(value),
    );
  }
}

String _$cancelModelDownloadHash() =>
    r'2503afd1ff298f82106a64699d80d1c1ccf35141';
