// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_script_point.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(addScriptPoint)
final addScriptPointProvider = AddScriptPointProvider._();

final class AddScriptPointProvider
    extends $FunctionalProvider<AddScriptPoint, AddScriptPoint, AddScriptPoint>
    with $Provider<AddScriptPoint> {
  AddScriptPointProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addScriptPointProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addScriptPointHash();

  @$internal
  @override
  $ProviderElement<AddScriptPoint> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AddScriptPoint create(Ref ref) {
    return addScriptPoint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddScriptPoint value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddScriptPoint>(value),
    );
  }
}

String _$addScriptPointHash() => r'6ef4c87c7b355602daca36bf0592a71cb8d97bb8';
