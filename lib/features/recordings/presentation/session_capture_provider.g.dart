// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_capture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionCapture)
final sessionCaptureProvider = SessionCaptureFamily._();

final class SessionCaptureProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionCaptureState>,
          SessionCaptureState,
          Stream<SessionCaptureState>
        >
    with
        $FutureModifier<SessionCaptureState>,
        $StreamProvider<SessionCaptureState> {
  SessionCaptureProvider._({
    required SessionCaptureFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionCaptureProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionCaptureHash();

  @override
  String toString() {
    return r'sessionCaptureProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SessionCaptureState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionCaptureState> create(Ref ref) {
    final argument = this.argument as String;
    return sessionCapture(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionCaptureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionCaptureHash() => r'2c80e5847a6665c045014e1a2c4ba523d703adbb';

final class SessionCaptureFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SessionCaptureState>, String> {
  SessionCaptureFamily._()
    : super(
        retry: null,
        name: r'sessionCaptureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionCaptureProvider call(String sessionId) =>
      SessionCaptureProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionCaptureProvider';
}
