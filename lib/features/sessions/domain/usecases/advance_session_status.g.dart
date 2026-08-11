// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advance_session_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(advanceSessionStatus)
final advanceSessionStatusProvider = AdvanceSessionStatusProvider._();

final class AdvanceSessionStatusProvider
    extends
        $FunctionalProvider<
          AdvanceSessionStatus,
          AdvanceSessionStatus,
          AdvanceSessionStatus
        >
    with $Provider<AdvanceSessionStatus> {
  AdvanceSessionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'advanceSessionStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$advanceSessionStatusHash();

  @$internal
  @override
  $ProviderElement<AdvanceSessionStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdvanceSessionStatus create(Ref ref) {
    return advanceSessionStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdvanceSessionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdvanceSessionStatus>(value),
    );
  }
}

String _$advanceSessionStatusHash() =>
    r'ad124309e7afa6dd67f0fd1065947ec5647d64cb';
