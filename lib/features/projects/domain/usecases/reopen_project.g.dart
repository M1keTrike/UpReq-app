// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reopen_project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reopenProject)
final reopenProjectProvider = ReopenProjectProvider._();

final class ReopenProjectProvider
    extends $FunctionalProvider<ReopenProject, ReopenProject, ReopenProject>
    with $Provider<ReopenProject> {
  ReopenProjectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reopenProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reopenProjectHash();

  @$internal
  @override
  $ProviderElement<ReopenProject> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReopenProject create(Ref ref) {
    return reopenProject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReopenProject value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReopenProject>(value),
    );
  }
}

String _$reopenProjectHash() => r'2ea4314da4fcefe57b94e4a819e39ed1063e847a';
