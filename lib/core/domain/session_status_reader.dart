import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

/// Único punto por el que la feature de grabaciones conoce el estado de una
/// sesión sin importar `features/sessions` (aislamiento entre features,
/// mismo patrón que `ProjectStatusReader`). `StartRecording` lo consulta
/// antes de grabar (FR-003): el proyecto debe estar activo y la sesión en
/// curso.
abstract interface class SessionStatusReader {
  Future<SessionSnapshot?> find(SessionId id);
}

class SessionSnapshot {
  const SessionSnapshot({required this.projectId, required this.isInProgress});

  final ProjectId projectId;
  final bool isInProgress;
}

/// Placeholder deliberado: `core` no puede importar `features/sessions` (esa
/// dirección de dependencia está invertida), así que este provider lanza por
/// defecto y `main.dart` lo sobreescribe con la implementación real.
final sessionStatusReaderProvider = Provider<SessionStatusReader>((ref) {
  throw UnimplementedError(
    'sessionStatusReaderProvider debe sobreescribirse en main.dart con la '
    'implementación de la feature de sesiones.',
  );
});
