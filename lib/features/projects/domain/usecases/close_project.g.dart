// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'close_project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(closeProject)
final closeProjectProvider = CloseProjectProvider._();

final class CloseProjectProvider
    extends $FunctionalProvider<CloseProject, CloseProject, CloseProject>
    with $Provider<CloseProject> {
  CloseProjectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'closeProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$closeProjectHash();

  @$internal
  @override
  $ProviderElement<CloseProject> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloseProject create(Ref ref) {
    return closeProject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloseProject value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloseProject>(value),
    );
  }
}

String _$closeProjectHash() => r'30047054309b9270e54032ccda40a05065a15853';
