// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_script_point_text.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateScriptPointText)
final updateScriptPointTextProvider = UpdateScriptPointTextProvider._();

final class UpdateScriptPointTextProvider
    extends
        $FunctionalProvider<
          UpdateScriptPointText,
          UpdateScriptPointText,
          UpdateScriptPointText
        >
    with $Provider<UpdateScriptPointText> {
  UpdateScriptPointTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateScriptPointTextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateScriptPointTextHash();

  @$internal
  @override
  $ProviderElement<UpdateScriptPointText> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateScriptPointText create(Ref ref) {
    return updateScriptPointText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateScriptPointText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateScriptPointText>(value),
    );
  }
}

String _$updateScriptPointTextHash() =>
    r'8426ea41229283a1a24d974f5f5e1d216d5360ec';
