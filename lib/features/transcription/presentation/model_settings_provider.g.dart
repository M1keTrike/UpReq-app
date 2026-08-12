// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelSettings)
final modelSettingsProvider = ModelSettingsProvider._();

final class ModelSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelSettingsState>,
          ModelSettingsState,
          Stream<ModelSettingsState>
        >
    with
        $FutureModifier<ModelSettingsState>,
        $StreamProvider<ModelSettingsState> {
  ModelSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelSettingsHash();

  @$internal
  @override
  $StreamProviderElement<ModelSettingsState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ModelSettingsState> create(Ref ref) {
    return modelSettings(ref);
  }
}

String _$modelSettingsHash() => r'5e96a952e3d5b4582ee6f36656973e3e5aa11bf9';
