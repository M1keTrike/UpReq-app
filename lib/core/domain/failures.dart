/// Fallos tipados de dominio. Ver data-model.md, sección "Fallos tipados del dominio".
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ProjectClosedFailure extends Failure {
  const ProjectClosedFailure(super.message);
}

final class InvalidSessionTransitionFailure extends Failure {
  const InvalidSessionTransitionFailure(super.message);
}

final class SessionHeaderFrozenFailure extends Failure {
  const SessionHeaderFrozenFailure(super.message);
}

final class CrossProjectReferenceFailure extends Failure {
  const CrossProjectReferenceFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
