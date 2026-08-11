// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createSession)
final createSessionProvider = CreateSessionProvider._();

final class CreateSessionProvider
    extends $FunctionalProvider<CreateSession, CreateSession, CreateSession>
    with $Provider<CreateSession> {
  CreateSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createSessionHash();

  @$internal
  @override
  $ProviderElement<CreateSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateSession create(Ref ref) {
    return createSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateSession>(value),
    );
  }
}

String _$createSessionHash() => r'b5de1b98e87efd62ab0c96a17650ab5809264134';
