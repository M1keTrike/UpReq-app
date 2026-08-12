// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_live_mark.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteLiveMark)
final deleteLiveMarkProvider = DeleteLiveMarkProvider._();

final class DeleteLiveMarkProvider
    extends $FunctionalProvider<DeleteLiveMark, DeleteLiveMark, DeleteLiveMark>
    with $Provider<DeleteLiveMark> {
  DeleteLiveMarkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteLiveMarkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteLiveMarkHash();

  @$internal
  @override
  $ProviderElement<DeleteLiveMark> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteLiveMark create(Ref ref) {
    return deleteLiveMark(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteLiveMark value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteLiveMark>(value),
    );
  }
}

String _$deleteLiveMarkHash() => r'fa6a1f43dad65cce45892791bfca1a0cd114bddb';
