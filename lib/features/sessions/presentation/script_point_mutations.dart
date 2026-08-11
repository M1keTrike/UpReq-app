import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/script_point.dart';
import '../domain/usecases/add_script_point.dart';
import '../domain/usecases/delete_script_point.dart';
import '../domain/usecases/mark_script_point.dart';
import '../domain/usecases/reorder_script_point.dart';
import '../domain/usecases/update_script_point_text.dart';

final addScriptPoint = Mutation<ScriptPointId>();
final saveScriptPointText = Mutation<void>();
final markScriptPoint = Mutation<void>();
final reorderScriptPoint = Mutation<void>();
final deleteScriptPoint = Mutation<void>();

Future<ScriptPointId> runAddScriptPoint(MutationTarget target, SessionId sessionId, String text) {
  return addScriptPoint.run(target, (tsx) async {
    final result = await tsx.get(addScriptPointProvider)(sessionId, text);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runSaveScriptPointText(MutationTarget target, ScriptPointId id, String text) {
  return saveScriptPointText.run(target, (tsx) async {
    final result = await tsx.get(updateScriptPointTextProvider)(id, text);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runMarkScriptPoint(MutationTarget target, ScriptPointId id, ScriptPointStatus status) {
  return markScriptPoint.run(target, (tsx) async {
    final result = await tsx.get(markScriptPointProvider)(id, status);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runReorderScriptPoint(
  MutationTarget target,
  SessionId sessionId,
  ScriptPointId id,
  int from,
  int to,
) {
  return reorderScriptPoint.run(target, (tsx) async {
    final result = await tsx.get(reorderScriptPointProvider)(sessionId, id, from, to);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeleteScriptPoint(MutationTarget target, ScriptPointId id) {
  return deleteScriptPoint.run(target, (tsx) async {
    final result = await tsx.get(deleteScriptPointProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
