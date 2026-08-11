import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';

import '../data/session_repository_impl.dart';
import '../domain/entities/elicitation_session.dart';

part 'session_form_provider.g.dart';

final class SessionFormState {
  const SessionFormState({
    required this.projectId,
    required this.scheduledAt,
    this.sessionId,
    this.title = '',
    this.technique = SessionTechnique.openInterview,
    this.location,
    this.notes,
    this.participantIds = const [],
    this.status = SessionStatus.planned,
    this.isReadOnly = false,
  });

  final ProjectId projectId;

  /// `null` en modo creación.
  final SessionId? sessionId;
  final String title;
  final DateTime scheduledAt;
  final SessionTechnique technique;
  final String? location;
  final String? notes;
  final List<StakeholderId> participantIds;
  final SessionStatus status;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): con el proyecto
  /// cerrado, todo el formulario —incluidas notas— se muestra en solo
  /// lectura. Distinto de [isHeaderFrozen], que es propio de la sesión.
  final bool isReadOnly;

  bool get isEditing => sessionId != null;

  /// Cabecera congelada con la sesión cerrada (FR-008b, invariante I7): las
  /// notas y el guion siguen siendo editables, la cabecera no.
  bool get isHeaderFrozen => status == SessionStatus.closed;

  SessionFormState copyWith({
    String? title,
    DateTime? scheduledAt,
    SessionTechnique? technique,
    String? location,
    String? notes,
    List<StakeholderId>? participantIds,
  }) {
    return SessionFormState(
      projectId: projectId,
      sessionId: sessionId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      technique: technique ?? this.technique,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      participantIds: participantIds ?? this.participantIds,
      status: status,
      isReadOnly: isReadOnly,
    );
  }
}

/// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
/// 5. Al fallar la validación de una escritura, este estado no se toca: es
/// lo que conserva lo escrito (FR-022).
@riverpod
class SessionForm extends _$SessionForm {
  @override
  Future<SessionFormState> build(String projectId, String? sessionId) async {
    final statusReader = ref.watch(projectStatusReaderProvider);

    if (sessionId == null) {
      final now = ref.watch(clockProvider).now();
      final isActive = await statusReader.isActive(ProjectId(projectId));
      return SessionFormState(
        projectId: ProjectId(projectId),
        scheduledAt: now,
        isReadOnly: !isActive,
      );
    }

    final repository = ref.watch(sessionRepositoryProvider);
    final detail = await repository.watchDetail(SessionId(sessionId)).first;
    if (detail == null) {
      throw NotFoundFailure('No se encontró la sesión $sessionId.');
    }
    final isActive = await statusReader.isActive(detail.session.projectId);

    return SessionFormState(
      projectId: detail.session.projectId,
      sessionId: detail.session.id,
      title: detail.session.title,
      scheduledAt: detail.session.scheduledAt,
      technique: detail.session.technique,
      location: detail.session.location,
      notes: detail.session.notes,
      participantIds: detail.participantIds,
      status: detail.session.status,
      isReadOnly: !isActive,
    );
  }

  void updateTitle(String title) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(title: title));
  }

  void updateScheduledAt(DateTime scheduledAt) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(scheduledAt: scheduledAt));
  }

  void updateTechnique(SessionTechnique technique) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(technique: technique));
  }

  void updateLocation(String? location) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(location: location));
  }

  void updateNotes(String? notes) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notes: notes));
  }

  void toggleParticipant(StakeholderId id) {
    final current = state.value;
    if (current == null) return;
    final ids = [...current.participantIds];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = AsyncData(current.copyWith(participantIds: ids));
  }
}

/// Alimenta el selector de participantes con `watchSelectableByProject`, de
/// modo que estructuralmente no puede ofrecer interesados inactivos ni de
/// otro proyecto (FR-009, ui-contracts.md pantalla 5).
@riverpod
Stream<List<Stakeholder>> selectableStakeholders(Ref ref, String projectId) {
  final repository = ref.watch(stakeholderRepositoryProvider);
  return repository.watchSelectableByProject(ProjectId(projectId));
}
