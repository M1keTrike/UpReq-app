import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

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

Future<void> runAdvanceSessionStatus(MutationTarget target, SessionId id, SessionStatus to) {
  return advanceSessionStatus.run(target, (tsx) async {
    final result = await tsx.get(advanceSessionStatusProvider)(id, to);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
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
