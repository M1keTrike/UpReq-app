// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_script_point.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reorderScriptPoint)
final reorderScriptPointProvider = ReorderScriptPointProvider._();

final class ReorderScriptPointProvider
    extends
        $FunctionalProvider<
          ReorderScriptPoint,
          ReorderScriptPoint,
          ReorderScriptPoint
        >
    with $Provider<ReorderScriptPoint> {
  ReorderScriptPointProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reorderScriptPointProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reorderScriptPointHash();

  @$internal
  @override
  $ProviderElement<ReorderScriptPoint> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReorderScriptPoint create(Ref ref) {
    return reorderScriptPoint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReorderScriptPoint value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReorderScriptPoint>(value),
    );
  }
}

String _$reorderScriptPointHash() =>
    r'48401256a161ce04a0f580042ae8d23e938a9013';
