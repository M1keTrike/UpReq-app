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

/// Incremento 2 — captura y transcripción. Ver contracts/domain-contracts.md.
final class MicrophonePermissionDenied extends Failure {
  const MicrophonePermissionDenied(super.message);
}

final class SessionNotInProgressFailure extends Failure {
  const SessionNotInProgressFailure(super.message);
}

final class RecordingAlreadyActiveFailure extends Failure {
  const RecordingAlreadyActiveFailure(super.message);
}

final class NoActiveRecordingFailure extends Failure {
  const NoActiveRecordingFailure(super.message);
}

final class StorageFullFailure extends Failure {
  const StorageFullFailure(super.message);
}

final class ModelUnavailableFailure extends Failure {
  const ModelUnavailableFailure(super.message);
}

final class DownloadFailure extends Failure {
  const DownloadFailure(super.message);
}

final class TranscriptionFailure extends Failure {
  const TranscriptionFailure(super.message);
}
