// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_session_notes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateSessionNotes)
final updateSessionNotesProvider = UpdateSessionNotesProvider._();

final class UpdateSessionNotesProvider
    extends
        $FunctionalProvider<
          UpdateSessionNotes,
          UpdateSessionNotes,
          UpdateSessionNotes
        >
    with $Provider<UpdateSessionNotes> {
  UpdateSessionNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateSessionNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateSessionNotesHash();

  @$internal
  @override
  $ProviderElement<UpdateSessionNotes> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateSessionNotes create(Ref ref) {
    return updateSessionNotes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateSessionNotes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateSessionNotes>(value),
    );
  }
}

String _$updateSessionNotesHash() =>
    r'5f5f70e865826617959ccda0ab2b560573aa59ab';
