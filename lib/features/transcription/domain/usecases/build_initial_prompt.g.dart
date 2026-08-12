// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_initial_prompt.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildInitialPrompt)
final buildInitialPromptProvider = BuildInitialPromptProvider._();

final class BuildInitialPromptProvider
    extends
        $FunctionalProvider<
          BuildInitialPrompt,
          BuildInitialPrompt,
          BuildInitialPrompt
        >
    with $Provider<BuildInitialPrompt> {
  BuildInitialPromptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildInitialPromptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildInitialPromptHash();

  @$internal
  @override
  $ProviderElement<BuildInitialPrompt> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuildInitialPrompt create(Ref ref) {
    return buildInitialPrompt(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildInitialPrompt value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildInitialPrompt>(value),
    );
  }
}

String _$buildInitialPromptHash() =>
    r'7cd8f59c81dccef6100d90382cb8fbe6cb07fc79';
