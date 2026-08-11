import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/script_point_repository_impl.dart';
import '../../data/session_repository_impl.dart';
import '../entities/script_point.dart';
import '../script_point_repository.dart';
import '../session_repository.dart';

part 'add_script_point.g.dart';

final class AddScriptPoint {
  const AddScriptPoint(
    this._repository,
    this._sessionRepository,
    this._statusReader,
    this._clock,
    this._idGenerator,
  );

  final ScriptPointRepository _repository;
  final SessionRepository _sessionRepository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;
  final IdGenerator _idGenerator;

  /// `text` obligatorio; el punto nuevo toma `position = n` (FR-010).
  Future<Result<ScriptPointId>> call(SessionId sessionId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('El texto del punto es obligatorio.'));
    }
    if (trimmed.length > 500) {
      return const Err(
        ValidationFailure('El texto del punto no puede superar los 500 caracteres.'),
      );
    }

    final session = await _sessionRepository.findById(sessionId);
    if (session == null) {
      return Err(NotFoundFailure('No se encontró la sesión $sessionId.'));
    }
    if (!await _statusReader.isActive(session.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${session.projectId} está cerrado.'));
    }

    final currentPoints = await _repository.watchBySession(sessionId).first;
    final now = _clock.now();
    final point = ScriptPoint(
      id: ScriptPointId(_idGenerator.generate()),
      sessionId: sessionId,
      projectId: session.projectId,
      text: trimmed,
      status: ScriptPointStatus.pending,
      position: currentPoints.length,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.append(point);
    return Ok(point.id);
  }
}

@riverpod
AddScriptPoint addScriptPoint(Ref ref) {
  return AddScriptPoint(
    ref.watch(scriptPointRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  );
}
