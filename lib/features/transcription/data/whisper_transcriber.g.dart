// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whisper_transcriber.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transcriber)
final transcriberProvider = TranscriberProvider._();

final class TranscriberProvider
    extends $FunctionalProvider<Transcriber, Transcriber, Transcriber>
    with $Provider<Transcriber> {
  TranscriberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transcriberProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transcriberHash();

  @$internal
  @override
  $ProviderElement<Transcriber> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Transcriber create(Ref ref) {
    return transcriber(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Transcriber value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Transcriber>(value),
    );
  }
}

String _$transcriberHash() => r'c4a99a264ae4d58493a1b426ae000b9a97c165d8';
