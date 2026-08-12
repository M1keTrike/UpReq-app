// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_final_pass.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runFinalPass)
final runFinalPassProvider = RunFinalPassProvider._();

final class RunFinalPassProvider
    extends $FunctionalProvider<RunFinalPass, RunFinalPass, RunFinalPass>
    with $Provider<RunFinalPass> {
  RunFinalPassProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runFinalPassProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runFinalPassHash();

  @$internal
  @override
  $ProviderElement<RunFinalPass> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RunFinalPass create(Ref ref) {
    return runFinalPass(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunFinalPass value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunFinalPass>(value),
    );
  }
}

String _$runFinalPassHash() => r'baf9a834d9281682fea03627714878cb96e24c92';
