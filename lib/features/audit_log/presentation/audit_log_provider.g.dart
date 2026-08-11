// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Único provider que consume la pantalla de bitácora (ui-contracts.md,
/// pantalla 8). No hay archivo de mutaciones: esta historia no expone
/// ninguna escritura.

@ProviderFor(auditLog)
final auditLogProvider = AuditLogFamily._();

/// Único provider que consume la pantalla de bitácora (ui-contracts.md,
/// pantalla 8). No hay archivo de mutaciones: esta historia no expone
/// ninguna escritura.

final class AuditLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuditLogState>,
          AuditLogState,
          Stream<AuditLogState>
        >
    with $FutureModifier<AuditLogState>, $StreamProvider<AuditLogState> {
  /// Único provider que consume la pantalla de bitácora (ui-contracts.md,
  /// pantalla 8). No hay archivo de mutaciones: esta historia no expone
  /// ninguna escritura.
  AuditLogProvider._({
    required AuditLogFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'auditLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$auditLogHash();

  @override
  String toString() {
    return r'auditLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<AuditLogState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuditLogState> create(Ref ref) {
    final argument = this.argument as String;
    return auditLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$auditLogHash() => r'2adfedef0af10e01a62aadc07aa0850462c2e681';

/// Único provider que consume la pantalla de bitácora (ui-contracts.md,
/// pantalla 8). No hay archivo de mutaciones: esta historia no expone
/// ninguna escritura.

final class AuditLogFamily extends $Family
    with $FunctionalFamilyOverride<Stream<AuditLogState>, String> {
  AuditLogFamily._()
    : super(
        retry: null,
        name: r'auditLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Único provider que consume la pantalla de bitácora (ui-contracts.md,
  /// pantalla 8). No hay archivo de mutaciones: esta historia no expone
  /// ninguna escritura.

  AuditLogProvider call(String projectId) =>
      AuditLogProvider._(argument: projectId, from: this);

  @override
  String toString() => r'auditLogProvider';
}
