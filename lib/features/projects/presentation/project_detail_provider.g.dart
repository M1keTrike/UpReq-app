// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectDetail)
final projectDetailProvider = ProjectDetailFamily._();

final class ProjectDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProjectDetailState>,
          ProjectDetailState,
          Stream<ProjectDetailState>
        >
    with
        $FutureModifier<ProjectDetailState>,
        $StreamProvider<ProjectDetailState> {
  ProjectDetailProvider._({
    required ProjectDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectDetailHash();

  @override
  String toString() {
    return r'projectDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ProjectDetailState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProjectDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return projectDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectDetailHash() => r'08e8ce037bb1d69c147657dc5f2a2fbf1452f594';

final class ProjectDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ProjectDetailState>, String> {
  ProjectDetailFamily._()
    : super(
        retry: null,
        name: r'projectDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectDetailProvider call(String projectId) =>
      ProjectDetailProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectDetailProvider';
}
