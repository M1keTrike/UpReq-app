// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_mark_kind.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(changeMarkKind)
final changeMarkKindProvider = ChangeMarkKindProvider._();

final class ChangeMarkKindProvider
    extends $FunctionalProvider<ChangeMarkKind, ChangeMarkKind, ChangeMarkKind>
    with $Provider<ChangeMarkKind> {
  ChangeMarkKindProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeMarkKindProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeMarkKindHash();

  @$internal
  @override
  $ProviderElement<ChangeMarkKind> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChangeMarkKind create(Ref ref) {
    return changeMarkKind(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangeMarkKind value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangeMarkKind>(value),
    );
  }
}

String _$changeMarkKindHash() => r'b743494021021ddba7c8875fcd23129aec02f7ca';
