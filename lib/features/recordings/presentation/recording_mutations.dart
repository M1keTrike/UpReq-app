import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/live_mark.dart';
import '../domain/usecases/change_mark_kind.dart';
import '../domain/usecases/delete_live_mark.dart';
import '../domain/usecases/delete_recording.dart';
import '../domain/usecases/place_live_mark.dart';
import 'active_capture_notifier.dart';

final startRecording = Mutation<RecordingId>();
final stopRecording = Mutation<void>();
final deleteRecording = Mutation<void>();
final placeLiveMark = Mutation<LiveMarkId>();
final changeMarkKind = Mutation<void>();
final deleteLiveMark = Mutation<void>();

Future<RecordingId> runStartRecording(MutationTarget target, SessionId sessionId) {
  return startRecording.run(target, (tsx) async {
    final notifier = tsx.get(activeCaptureProvider.notifier);
    final result = await notifier.start(sessionId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runStopRecording(MutationTarget target) {
  return stopRecording.run(target, (tsx) async {
    final notifier = tsx.get(activeCaptureProvider.notifier);
    final result = await notifier.stop();
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeleteRecording(MutationTarget target, RecordingId id) {
  return deleteRecording.run(target, (tsx) async {
    final result = await tsx.get(deleteRecordingProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

/// Coloca la marca y avisa al notifier de captura para que el contador
/// visible de `marksPlaced` avance (ui-contracts.md, `ActiveCapture`).
Future<LiveMarkId> runPlaceLiveMark(MutationTarget target, RecordingId recordingId, LiveMarkKind kind) {
  return placeLiveMark.run(target, (tsx) async {
    final result = await tsx.get(placeLiveMarkProvider)(recordingId, kind);
    switch (result) {
      case Ok(:final value):
        tsx.get(activeCaptureProvider.notifier).noteMarkPlaced();
        return value;
      case Err(:final failure):
        throw failure;
    }
  });
}

Future<void> runChangeMarkKind(MutationTarget target, LiveMarkId id, LiveMarkKind kind) {
  return changeMarkKind.run(target, (tsx) async {
    final result = await tsx.get(changeMarkKindProvider)(id, kind);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeleteLiveMark(MutationTarget target, LiveMarkId id) {
  return deleteLiveMark.run(target, (tsx) async {
    final result = await tsx.get(deleteLiveMarkProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
