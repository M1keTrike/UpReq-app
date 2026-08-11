// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_script_point.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteScriptPoint)
final deleteScriptPointProvider = DeleteScriptPointProvider._();

final class DeleteScriptPointProvider
    extends
        $FunctionalProvider<
          DeleteScriptPoint,
          DeleteScriptPoint,
          DeleteScriptPoint
        >
    with $Provider<DeleteScriptPoint> {
  DeleteScriptPointProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteScriptPointProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteScriptPointHash();

  @$internal
  @override
  $ProviderElement<DeleteScriptPoint> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteScriptPoint create(Ref ref) {
    return deleteScriptPoint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteScriptPoint value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteScriptPoint>(value),
    );
  }
}

String _$deleteScriptPointHash() => r'8a5e4e84a2c988bd2c7c81f59fa22ddf0b7a839d';
