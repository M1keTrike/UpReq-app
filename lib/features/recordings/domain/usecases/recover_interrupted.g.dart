// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recover_interrupted.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recoverInterrupted)
final recoverInterruptedProvider = RecoverInterruptedProvider._();

final class RecoverInterruptedProvider
    extends
        $FunctionalProvider<
          RecoverInterrupted,
          RecoverInterrupted,
          RecoverInterrupted
        >
    with $Provider<RecoverInterrupted> {
  RecoverInterruptedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recoverInterruptedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recoverInterruptedHash();

  @$internal
  @override
  $ProviderElement<RecoverInterrupted> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecoverInterrupted create(Ref ref) {
    return recoverInterrupted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecoverInterrupted value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecoverInterrupted>(value),
    );
  }
}

String _$recoverInterruptedHash() =>
    r'8c36a6b19655667cf0b374034beb5f7ccbee9a16';
