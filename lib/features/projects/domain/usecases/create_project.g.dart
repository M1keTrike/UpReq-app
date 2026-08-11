// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createProject)
final createProjectProvider = CreateProjectProvider._();

final class CreateProjectProvider
    extends $FunctionalProvider<CreateProject, CreateProject, CreateProject>
    with $Provider<CreateProject> {
  CreateProjectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createProjectHash();

  @$internal
  @override
  $ProviderElement<CreateProject> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateProject create(Ref ref) {
    return createProject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateProject value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateProject>(value),
    );
  }
}

String _$createProjectHash() => r'0fcd0d9b37fd7b55ee020ea00043ab877bfa17b5';
