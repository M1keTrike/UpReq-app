// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handle_interruption.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(handleInterruption)
final handleInterruptionProvider = HandleInterruptionProvider._();

final class HandleInterruptionProvider
    extends
        $FunctionalProvider<
          HandleInterruption,
          HandleInterruption,
          HandleInterruption
        >
    with $Provider<HandleInterruption> {
  HandleInterruptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handleInterruptionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handleInterruptionHash();

  @$internal
  @override
  $ProviderElement<HandleInterruption> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HandleInterruption create(Ref ref) {
    return handleInterruption(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HandleInterruption value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HandleInterruption>(value),
    );
  }
}

String _$handleInterruptionHash() =>
    r'081fdbccc3fd0232833c72e03ed3e1ed323be063';
