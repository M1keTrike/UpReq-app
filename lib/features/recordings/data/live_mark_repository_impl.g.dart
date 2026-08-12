// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_mark_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(liveMarkRepository)
final liveMarkRepositoryProvider = LiveMarkRepositoryProvider._();

final class LiveMarkRepositoryProvider
    extends
        $FunctionalProvider<
          LiveMarkRepository,
          LiveMarkRepository,
          LiveMarkRepository
        >
    with $Provider<LiveMarkRepository> {
  LiveMarkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveMarkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveMarkRepositoryHash();

  @$internal
  @override
  $ProviderElement<LiveMarkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiveMarkRepository create(Ref ref) {
    return liveMarkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveMarkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveMarkRepository>(value),
    );
  }
}

String _$liveMarkRepositoryHash() =>
    r'7a05e3dd46ea6c27081e35468ec2b7bd420ecf51';
