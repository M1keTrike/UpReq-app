import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/core/domain/session_status_reader.dart';

import '../../data/record_audio_recorder.dart';
import '../../data/recording_repository_impl.dart';
import '../contracts/audio_recorder.dart';
import '../contracts/recording_repository.dart';
import '../entities/recording.dart';

part 'start_recording.g.dart';

/// Valida las precondiciones (FR-003, FR-004, invariante R1) y persiste la
/// fila de la grabación. Abrir el escritor WAV real y el flujo PCM es
/// responsabilidad de `ActiveCaptureNotifier`: son recursos de dispositivo
/// con un ciclo de vida más largo que esta llamada, y el notifier —
/// `keepAlive` a propósito — es quien los posee mientras dura la captura.
final class StartRecording {
  const StartRecording(
    this._repository,
    this._sessionStatusReader,
    this._projectStatusReader,
    this._audioRecorder,
    this._idGenerator,
    this._clock,
  );

  final RecordingRepository _repository;
  final SessionStatusReader _sessionStatusReader;
  final ProjectStatusReader _projectStatusReader;
  final AudioRecorder _audioRecorder;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<RecordingId>> call(SessionId sessionId) async {
    final session = await _sessionStatusReader.find(sessionId);
    if (session == null) {
      return Err(NotFoundFailure('No se encontró la sesión $sessionId.'));
    }
    if (!await _projectStatusReader.isActive(session.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${session.projectId} está cerrado.'));
    }
    if (!session.isInProgress) {
      return Err(SessionNotInProgressFailure('La sesión $sessionId no está en curso.'));
    }

    final active = await _repository.watchActive().first;
    if (active != null) {
      return Err(RecordingAlreadyActiveFailure('Ya hay una grabación activa (${active.id}).'));
    }

    if (!await _audioRecorder.hasPermission()) {
      return Err(MicrophonePermissionDenied('Falta el permiso de micrófono.'));
    }

    final now = _clock.now();
    final id = RecordingId(_idGenerator.generate());
    final recording = Recording(
      id: id,
      sessionId: sessionId,
      projectId: session.projectId,
      filePath: 'recordings/${id.value}.wav',
      status: RecordingStatus.recording,
      durationMs: 0,
      sampleRate: 16000,
      channels: 1,
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insert(recording);
    return Ok(id);
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T040), que también es
// keepAlive; riverpod_lint exige que un provider keepAlive no dependa de uno
// autoDispose (only_use_keep_alive_inside_keep_alive).
@Riverpod(keepAlive: true)
StartRecording startRecording(Ref ref) {
  return StartRecording(
    ref.watch(recordingRepositoryProvider),
    ref.watch(sessionStatusReaderProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(audioRecorderProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
}
