import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

/// Único punto por el que una feature conoce el estado de un proyecto sin
/// importar otra feature (aislamiento entre features). Implementado por la
/// feature de proyectos, registrado en `core` mediante un provider. Toda
/// escritura de cualquier feature lo consulta primero (FR-004a).
abstract interface class ProjectStatusReader {
  Future<bool> isActive(ProjectId id);
}

/// Placeholder deliberado: `core` no puede importar `features/projects` (esa
/// dirección de dependencia está invertida), así que este provider lanza por
/// defecto y `main.dart` —el único sitio que conoce todas las features— lo
/// sobreescribe con la implementación real (T042).
final projectStatusReaderProvider = Provider<ProjectStatusReader>((ref) {
  throw UnimplementedError(
    'projectStatusReaderProvider debe sobreescribirse en main.dart con la '
    'implementación de la feature de proyectos.',
  );
});
