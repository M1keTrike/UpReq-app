import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/session_transition.dart';

void main() {
  // Las nueve combinaciones de la tabla de data-model.md (invariante I6):
  // solo el avance planned -> inProgress -> closed es válido; cualquier
  // retroceso, o quedarse en el mismo estado, es inválido.
  final validTransitions = <(SessionStatus, SessionStatus)>{
    (SessionStatus.planned, SessionStatus.inProgress),
    (SessionStatus.planned, SessionStatus.closed),
    (SessionStatus.inProgress, SessionStatus.closed),
  };

  for (final from in SessionStatus.values) {
    for (final to in SessionStatus.values) {
      final isValid = validTransitions.contains((from, to));

      test(
        '${from.name} -> ${to.name} es ${isValid ? "válida" : "inválida"}',
        () {
          final result = transitionSession(from, to);

          if (isValid) {
            expect(result, isA<Ok<SessionStatus>>());
            expect((result as Ok<SessionStatus>).value, to);
          } else {
            expect(result, isA<Err<SessionStatus>>());
            expect(
              (result as Err<SessionStatus>).failure,
              isA<InvalidSessionTransitionFailure>(),
            );
          }
        },
      );
    }
  }

  test('cubre exactamente las nueve combinaciones', () {
    expect(SessionStatus.values.length * SessionStatus.values.length, 9);
  });
}
