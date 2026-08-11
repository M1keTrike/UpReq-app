// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.

@ProviderFor(sessionDetail)
final sessionDetailProvider = SessionDetailFamily._();

/// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.

final class SessionDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionDetailState>,
          SessionDetailState,
          Stream<SessionDetailState>
        >
    with
        $FutureModifier<SessionDetailState>,
        $StreamProvider<SessionDetailState> {
  /// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.
  SessionDetailProvider._({
    required SessionDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionDetailHash();

  @override
  String toString() {
    return r'sessionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SessionDetailState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return sessionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionDetailHash() => r'e12517b1d01af292d75b841aaeb45f9ee53ceb23';

/// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.

final class SessionDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SessionDetailState>, String> {
  SessionDetailFamily._()
    : super(
        retry: null,
        name: r'sessionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.

  SessionDetailProvider call(String sessionId) =>
      SessionDetailProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionDetailProvider';
}
