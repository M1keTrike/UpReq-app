// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handle_storage_full.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(handleStorageFull)
final handleStorageFullProvider = HandleStorageFullProvider._();

final class HandleStorageFullProvider
    extends
        $FunctionalProvider<
          HandleStorageFull,
          HandleStorageFull,
          HandleStorageFull
        >
    with $Provider<HandleStorageFull> {
  HandleStorageFullProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handleStorageFullProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handleStorageFullHash();

  @$internal
  @override
  $ProviderElement<HandleStorageFull> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HandleStorageFull create(Ref ref) {
    return handleStorageFull(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HandleStorageFull value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HandleStorageFull>(value),
    );
  }
}

String _$handleStorageFullHash() => r'4940485a761e1078a8bafb5be179c12cf9654985';
