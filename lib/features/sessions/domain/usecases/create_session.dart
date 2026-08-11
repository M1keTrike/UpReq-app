import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';

import '../../data/session_repository_impl.dart';
import '../entities/elicitation_session.dart';
import '../entities/session_draft.dart';
import '../session_repository.dart';

part 'create_session.g.dart';

final class CreateSession {
  const CreateSession(
    this._repository,
    this._stakeholderRepository,
    this._statusReader,
    this._clock,
    this._idGenerator,
  );

  final SessionRepository _repository;
  final StakeholderRepository _stakeholderRepository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Future<Result<SessionId>> call(ProjectId projectId, SessionDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    if (!await _statusReader.isActive(projectId)) {
      return Err(ProjectClosedFailure('El proyecto $projectId está cerrado.'));
    }

    for (final participantId in draft.participantIds) {
      final stakeholder = await _stakeholderRepository.findById(participantId);
      if (stakeholder == null || stakeholder.projectId != projectId) {
        return Err(
          CrossProjectReferenceFailure(
            'El interesado $participantId no pertenece al proyecto $projectId.',
          ),
        );
      }
    }

    final now = _clock.now();
    final session = ElicitationSession(
      id: SessionId(_idGenerator.generate()),
      projectId: projectId,
      title: draft.title.trim(),
      scheduledAt: draft.scheduledAt,
      technique: draft.technique,
      location: draft.location,
      status: SessionStatus.planned,
      notes: draft.notes,
      closedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(session, draft.participantIds);
    return Ok(session.id);
  }
}

@riverpod
CreateSession createSession(Ref ref) {
  return CreateSession(
    ref.watch(sessionRepositoryProvider),
    ref.watch(stakeholderRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  );
}
