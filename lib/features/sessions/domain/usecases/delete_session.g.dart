// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteSession)
final deleteSessionProvider = DeleteSessionProvider._();

final class DeleteSessionProvider
    extends $FunctionalProvider<DeleteSession, DeleteSession, DeleteSession>
    with $Provider<DeleteSession> {
  DeleteSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteSessionHash();

  @$internal
  @override
  $ProviderElement<DeleteSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteSession create(Ref ref) {
    return deleteSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteSession>(value),
    );
  }
}

String _$deleteSessionHash() => r'1b01e4d8df9186074085361560ab5bccd7b8ae85';
