import 'package:up_req/core/domain/failures.dart';

/// Resultado de una operación de dominio que puede fallar de forma tipada.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
