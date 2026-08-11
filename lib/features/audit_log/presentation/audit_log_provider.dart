import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/audit_repository_impl.dart';
import '../domain/entities/audit_entry.dart';
import '../domain/usecases/watch_audit_log.dart';

part 'audit_log_provider.g.dart';

final class AuditLogState {
  const AuditLogState({required this.entries});

  final List<AuditEntry> entries;
}

/// Único provider que consume la pantalla de bitácora (ui-contracts.md,
/// pantalla 8). No hay archivo de mutaciones: esta historia no expone
/// ninguna escritura.
@riverpod
Stream<AuditLogState> auditLog(Ref ref, String projectId) {
  final repository = ref.watch(auditRepositoryProvider);
  return WatchAuditLog(repository)(ProjectId(projectId)).map(
        (entries) => AuditLogState(entries: entries),
      );
}
