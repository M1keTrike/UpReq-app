// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateProject)
final updateProjectProvider = UpdateProjectProvider._();

final class UpdateProjectProvider
    extends $FunctionalProvider<UpdateProject, UpdateProject, UpdateProject>
    with $Provider<UpdateProject> {
  UpdateProjectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateProjectHash();

  @$internal
  @override
  $ProviderElement<UpdateProject> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateProject create(Ref ref) {
    return updateProject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateProject value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateProject>(value),
    );
  }
}

String _$updateProjectHash() => r'385000c47e0aeb11f707da8fad7064b9715c364a';
