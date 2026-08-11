import 'package:up_req/core/domain/ids.dart';

/// Único punto por el que una feature conoce el estado de un proyecto sin
/// importar otra feature (aislamiento entre features). Implementado por la
/// feature de proyectos, registrado en `core` mediante un provider. Toda
/// escritura de cualquier feature lo consulta primero (FR-004a).
abstract interface class ProjectStatusReader {
  Future<bool> isActive(ProjectId id);
}
