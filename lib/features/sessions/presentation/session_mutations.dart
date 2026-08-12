import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/transcription/domain/usecases/run_final_pass.dart';

import '../domain/entities/elicitation_session.dart';
import '../domain/entities/session_draft.dart';
import '../domain/usecases/advance_session_status.dart';
import '../domain/usecases/create_session.dart';
import '../domain/usecases/delete_session.dart';
import '../domain/usecases/update_session_header.dart';
import '../domain/usecases/update_session_notes.dart';

final createSession = Mutation<SessionId>();
final saveSession = Mutation<void>();
final deleteSession = Mutation<void>();
final advanceSessionStatus = Mutation<void>();
final saveSessionNotes = Mutation<void>();

Future<SessionId> runCreateSession(
  MutationTarget target,
  ProjectId projectId,
  SessionDraft draft,
) {
  return createSession.run(target, (tsx) async {
    final result = await tsx.get(createSessionProvider)(projectId, draft);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runSaveSession(MutationTarget target, SessionId id, SessionDraft draft) {
  return saveSession.run(target, (tsx) async {
    final result = await tsx.get(updateSessionHeaderProvider)(id, draft);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeleteSession(MutationTarget target, SessionId id) {
  return deleteSession.run(target, (tsx) async {
    final result = await tsx.get(deleteSessionProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

/// Al cerrar (T084): detiene antes la grabación que siguiera activa de ESTA
/// sesión (FR-005), y tras confirmarse el cierre dispara `RunFinalPass`
/// sobre cada grabación no borrada de la sesión — puede haber varias
/// (FR-003a), y cada una produce su propia transcripción con sus propios
/// segmentos, sin que ninguna espere a las demás.
Future<void> runAdvanceSessionStatus(MutationTarget target, SessionId id, SessionStatus to) {
  return advanceSessionStatus.run(target, (tsx) async {
    if (to == SessionStatus.closed) {
      final active = tsx.get(activeCaptureProvider);
      if (active != null) {
        final activeRecording = await tsx.get(recordingRepositoryProvider).findById(active.id);
        if (activeRecording?.sessionId == id) {
          await tsx.get(activeCaptureProvider.notifier).stop();
        }
      }
    }

    final result = await tsx.get(advanceSessionStatusProvider)(id, to);
    if (result case Err(:final failure)) throw failure;

    if (to == SessionStatus.closed) {
      final recordings = await tsx.get(recordingRepositoryProvider).watchBySession(id).first;
      for (final recording in recordings) {
        await tsx.get(runFinalPassProvider)(recording.id);
      }
    }
  });
}

Future<void> runSaveSessionNotes(MutationTarget target, SessionId id, String? notes) {
  return saveSessionNotes.run(target, (tsx) async {
    final result = await tsx.get(updateSessionNotesProvider)(id, notes);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
