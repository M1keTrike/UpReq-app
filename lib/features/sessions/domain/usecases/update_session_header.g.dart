// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_session_header.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateSessionHeader)
final updateSessionHeaderProvider = UpdateSessionHeaderProvider._();

final class UpdateSessionHeaderProvider
    extends
        $FunctionalProvider<
          UpdateSessionHeader,
          UpdateSessionHeader,
          UpdateSessionHeader
        >
    with $Provider<UpdateSessionHeader> {
  UpdateSessionHeaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateSessionHeaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateSessionHeaderHash();

  @$internal
  @override
  $ProviderElement<UpdateSessionHeader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateSessionHeader create(Ref ref) {
    return updateSessionHeader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateSessionHeader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateSessionHeader>(value),
    );
  }
}

String _$updateSessionHeaderHash() =>
    r'b53ee462fb2cc94337648a3f0419f2ea44f7c287';
