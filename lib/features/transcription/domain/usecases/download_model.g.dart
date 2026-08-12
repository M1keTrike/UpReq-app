// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(downloadModel)
final downloadModelProvider = DownloadModelProvider._();

final class DownloadModelProvider
    extends $FunctionalProvider<DownloadModel, DownloadModel, DownloadModel>
    with $Provider<DownloadModel> {
  DownloadModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadModelHash();

  @$internal
  @override
  $ProviderElement<DownloadModel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadModel create(Ref ref) {
    return downloadModel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadModel>(value),
    );
  }
}

String _$downloadModelHash() => r'ba7da6f66e8400f4c3992ea225fe90f2cc8a096f';
