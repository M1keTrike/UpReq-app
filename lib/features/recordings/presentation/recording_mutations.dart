import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/usecases/delete_recording.dart';
import 'active_capture_notifier.dart';

final startRecording = Mutation<RecordingId>();
final stopRecording = Mutation<void>();
final deleteRecording = Mutation<void>();

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
