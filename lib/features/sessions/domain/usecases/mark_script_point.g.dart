// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_script_point.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(markScriptPoint)
final markScriptPointProvider = MarkScriptPointProvider._();

final class MarkScriptPointProvider
    extends
        $FunctionalProvider<MarkScriptPoint, MarkScriptPoint, MarkScriptPoint>
    with $Provider<MarkScriptPoint> {
  MarkScriptPointProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markScriptPointProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markScriptPointHash();

  @$internal
  @override
  $ProviderElement<MarkScriptPoint> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkScriptPoint create(Ref ref) {
    return markScriptPoint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkScriptPoint value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkScriptPoint>(value),
    );
  }
}

String _$markScriptPointHash() => r'7d39296623dda1b1479c7d909b396fe6f16f40b5';
