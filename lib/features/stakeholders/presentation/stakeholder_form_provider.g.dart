// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakeholder_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StakeholderForm)
final stakeholderFormProvider = StakeholderFormFamily._();

final class StakeholderFormProvider
    extends $AsyncNotifierProvider<StakeholderForm, StakeholderFormState> {
  StakeholderFormProvider._({
    required StakeholderFormFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'stakeholderFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stakeholderFormHash();

  @override
  String toString() {
    return r'stakeholderFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  StakeholderForm create() => StakeholderForm();

  @override
  bool operator ==(Object other) {
    return other is StakeholderFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stakeholderFormHash() => r'71bbf2fcbefe6a2ddd8be7b434427ba7707219f6';

final class StakeholderFormFamily extends $Family
    with
        $ClassFamilyOverride<
          StakeholderForm,
          AsyncValue<StakeholderFormState>,
          StakeholderFormState,
          FutureOr<StakeholderFormState>,
          (String, String?)
        > {
  StakeholderFormFamily._()
    : super(
        retry: null,
        name: r'stakeholderFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StakeholderFormProvider call(String projectId, String? stakeholderId) =>
      StakeholderFormProvider._(
        argument: (projectId, stakeholderId),
        from: this,
      );

  @override
  String toString() => r'stakeholderFormProvider';
}

abstract class _$StakeholderForm extends $AsyncNotifier<StakeholderFormState> {
  late final _$args = ref.$arg as (String, String?);
  String get projectId => _$args.$1;
  String? get stakeholderId => _$args.$2;

  FutureOr<StakeholderFormState> build(String projectId, String? stakeholderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<StakeholderFormState>, StakeholderFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<StakeholderFormState>,
                StakeholderFormState
              >,
              AsyncValue<StakeholderFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
