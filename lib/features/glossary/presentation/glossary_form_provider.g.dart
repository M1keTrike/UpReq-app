// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlossaryForm)
final glossaryFormProvider = GlossaryFormFamily._();

final class GlossaryFormProvider
    extends $AsyncNotifierProvider<GlossaryForm, GlossaryFormState> {
  GlossaryFormProvider._({
    required GlossaryFormFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'glossaryFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$glossaryFormHash();

  @override
  String toString() {
    return r'glossaryFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GlossaryForm create() => GlossaryForm();

  @override
  bool operator ==(Object other) {
    return other is GlossaryFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$glossaryFormHash() => r'67c416bee5b357ad90782d5e7dbceaf77bc1b65c';

final class GlossaryFormFamily extends $Family
    with
        $ClassFamilyOverride<
          GlossaryForm,
          AsyncValue<GlossaryFormState>,
          GlossaryFormState,
          FutureOr<GlossaryFormState>,
          (String, String?)
        > {
  GlossaryFormFamily._()
    : super(
        retry: null,
        name: r'glossaryFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GlossaryFormProvider call(String projectId, String? termId) =>
      GlossaryFormProvider._(argument: (projectId, termId), from: this);

  @override
  String toString() => r'glossaryFormProvider';
}

abstract class _$GlossaryForm extends $AsyncNotifier<GlossaryFormState> {
  late final _$args = ref.$arg as (String, String?);
  String get projectId => _$args.$1;
  String? get termId => _$args.$2;

  FutureOr<GlossaryFormState> build(String projectId, String? termId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GlossaryFormState>, GlossaryFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GlossaryFormState>, GlossaryFormState>,
              AsyncValue<GlossaryFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
