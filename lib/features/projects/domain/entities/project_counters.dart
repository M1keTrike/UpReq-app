/// Contadores del detalle de proyecto (FR-013): interesados activos,
/// sesiones vivas y términos de glosario vivos.
final class ProjectCounters {
  const ProjectCounters({
    required this.stakeholders,
    required this.sessions,
    required this.glossaryTerms,
  });

  final int stakeholders;
  final int sessions;
  final int glossaryTerms;

  @override
  bool operator ==(Object other) =>
      other is ProjectCounters &&
      other.stakeholders == stakeholders &&
      other.sessions == sessions &&
      other.glossaryTerms == glossaryTerms;

  @override
  int get hashCode => Object.hash(stakeholders, sessions, glossaryTerms);
}
