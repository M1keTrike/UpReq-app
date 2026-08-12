// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wav_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wavSink)
final wavSinkProvider = WavSinkProvider._();

final class WavSinkProvider
    extends $FunctionalProvider<WavSink, WavSink, WavSink>
    with $Provider<WavSink> {
  WavSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wavSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wavSinkHash();

  @$internal
  @override
  $ProviderElement<WavSink> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WavSink create(Ref ref) {
    return wavSink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WavSink value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WavSink>(value),
    );
  }
}

String _$wavSinkHash() => r'72721eb7f13c09b1f2ca7b1472b2483789affa46';
