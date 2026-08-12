// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_live_pass.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(startLivePass)
final startLivePassProvider = StartLivePassProvider._();

final class StartLivePassProvider
    extends $FunctionalProvider<StartLivePass, StartLivePass, StartLivePass>
    with $Provider<StartLivePass> {
  StartLivePassProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startLivePassProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startLivePassHash();

  @$internal
  @override
  $ProviderElement<StartLivePass> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartLivePass create(Ref ref) {
    return startLivePass(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartLivePass value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartLivePass>(value),
    );
  }
}

String _$startLivePassHash() => r'c56949b26bf9f81c1ab94262f172ca3afd305cd8';
