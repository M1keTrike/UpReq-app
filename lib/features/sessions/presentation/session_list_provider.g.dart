// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Único provider que consume la pantalla de lista de sesiones
/// (ui-contracts.md, pantalla 5).

@ProviderFor(sessionList)
final sessionListProvider = SessionListFamily._();

/// Único provider que consume la pantalla de lista de sesiones
/// (ui-contracts.md, pantalla 5).

final class SessionListProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionListState>,
          SessionListState,
          Stream<SessionListState>
        >
    with $FutureModifier<SessionListState>, $StreamProvider<SessionListState> {
  /// Único provider que consume la pantalla de lista de sesiones
  /// (ui-contracts.md, pantalla 5).
  SessionListProvider._({
    required SessionListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionListHash();

  @override
  String toString() {
    return r'sessionListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SessionListState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionListState> create(Ref ref) {
    final argument = this.argument as String;
    return sessionList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionListHash() => r'5e00fc59708d192320de38bd54809beeb1da7c3c';

/// Único provider que consume la pantalla de lista de sesiones
/// (ui-contracts.md, pantalla 5).

final class SessionListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SessionListState>, String> {
  SessionListFamily._()
    : super(
        retry: null,
        name: r'sessionListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Único provider que consume la pantalla de lista de sesiones
  /// (ui-contracts.md, pantalla 5).

  SessionListProvider call(String projectId) =>
      SessionListProvider._(argument: projectId, from: this);

  @override
  String toString() => r'sessionListProvider';
}
